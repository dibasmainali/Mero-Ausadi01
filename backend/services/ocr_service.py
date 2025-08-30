import cv2
import numpy as np
import pytesseract
from PIL import Image
import io
import base64
from typing import List, Dict, Any, Optional, Tuple
import re
from fuzzywuzzy import fuzz, process
import logging

from database.models import Medicine
from services.medicine_service import MedicineService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class OCRService:
    def __init__(self):
        self.medicine_service = MedicineService()
        
        # Configure Tesseract path for Windows
        try:
            pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
        except:
            # Use default path if not found
            pass

    def preprocess_image(self, image: np.ndarray) -> np.ndarray:
        """Preprocess image for better OCR results"""
        try:
            # Convert to grayscale
            if len(image.shape) == 3:
                gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            else:
                gray = image

            # Apply Gaussian blur to reduce noise
            blurred = cv2.GaussianBlur(gray, (5, 5), 0)

            # Apply threshold to get binary image
            _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

            # Apply morphological operations to clean up the image
            kernel = np.ones((1, 1), np.uint8)
            cleaned = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
            cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_OPEN, kernel)

            return cleaned

        except Exception as e:
            logger.error(f"Error preprocessing image: {e}")
            return image

    def extract_text_from_image(self, image: np.ndarray) -> str:
        """Extract text from image using OCR"""
        try:
            # Preprocess the image
            processed_image = self.preprocess_image(image)
            
            # Extract text using Tesseract
            text = pytesseract.image_to_string(processed_image, config='--psm 6')
            
            # Clean up the extracted text
            cleaned_text = self.clean_extracted_text(text)
            
            return cleaned_text

        except Exception as e:
            logger.error(f"Error extracting text from image: {e}")
            return ""

    def clean_extracted_text(self, text: str) -> str:
        """Clean and normalize extracted text"""
        try:
            # Remove extra whitespace and normalize
            text = re.sub(r'\s+', ' ', text.strip())
            
            # Remove special characters but keep alphanumeric, spaces, and common punctuation
            text = re.sub(r'[^\w\s\-\.\,\:\;\(\)\[\]\{\}]', '', text)
            
            # Remove multiple spaces
            text = re.sub(r'\s+', ' ', text)
            
            return text.strip()

        except Exception as e:
            logger.error(f"Error cleaning text: {e}")
            return text

    def extract_medicine_info(self, text: str) -> Dict[str, Any]:
        """Extract medicine information from OCR text"""
        try:
            info = {
                'brand_name': '',
                'generic_name': '',
                'strength': '',
                'manufacturer': '',
                'barcode': '',
                'confidence_score': 0.0
            }

            # Split text into lines
            lines = text.split('\n')
            
            # Look for patterns in the text
            for line in lines:
                line = line.strip()
                if not line:
                    continue

                # Extract barcode (look for numeric patterns)
                barcode_match = re.search(r'\b\d{8,13}\b', line)
                if barcode_match and not info['barcode']:
                    info['barcode'] = barcode_match.group()

                # Extract strength (look for mg, mcg, etc.)
                strength_match = re.search(r'\b\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml|IU)\b', line, re.IGNORECASE)
                if strength_match and not info['strength']:
                    info['strength'] = strength_match.group()

                # Look for manufacturer keywords
                manufacturer_keywords = ['ltd', 'inc', 'corp', 'pharma', 'pharmaceuticals', 'company']
                if any(keyword in line.lower() for keyword in manufacturer_keywords):
                    if not info['manufacturer']:
                        info['manufacturer'] = line

            # Try to identify brand name and generic name
            potential_names = self.extract_potential_names(lines)
            if potential_names:
                info['brand_name'] = potential_names.get('brand_name', '')
                info['generic_name'] = potential_names.get('generic_name', '')

            return info

        except Exception as e:
            logger.error(f"Error extracting medicine info: {e}")
            return info

    def extract_potential_names(self, lines: List[str]) -> Dict[str, str]:
        """Extract potential brand and generic names from text lines"""
        try:
            names = {'brand_name': '', 'generic_name': ''}
            
            # Look for lines that might contain medicine names
            for line in lines:
                line = line.strip()
                if not line or len(line) < 3:
                    continue

                # Skip lines that are likely not names
                if any(skip_word in line.lower() for skip_word in ['tablet', 'capsule', 'injection', 'mg', 'mcg', 'ml']):
                    continue

                # Look for lines that might be brand names (usually shorter, capitalized)
                if len(line) <= 30 and line.isupper():
                    if not names['brand_name']:
                        names['brand_name'] = line
                    continue

                # Look for lines that might be generic names (usually longer, mixed case)
                if len(line) > 10 and len(line) <= 50:
                    if not names['generic_name']:
                        names['generic_name'] = line
                    continue

            return names

        except Exception as e:
            logger.error(f"Error extracting potential names: {e}")
            return names

    def search_medicines_by_ocr_text(self, db, text: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Search medicines using OCR extracted text"""
        try:
            # Extract medicine information from OCR text
            medicine_info = self.extract_medicine_info(text)
            
            # Search for medicines using different strategies
            results = []
            
            # Strategy 1: Search by barcode if found
            if medicine_info['barcode']:
                medicine = self.medicine_service.get_medicine_by_barcode(db, medicine_info['barcode'])
                if medicine:
                    results.append({
                        'medicine': medicine,
                        'confidence_score': 0.95,
                        'matched_text': medicine_info['barcode'],
                        'match_type': 'barcode'
                    })

            # Strategy 2: Search by brand name
            if medicine_info['brand_name']:
                medicines = self.medicine_service.search_medicines(db, medicine_info['brand_name'], limit)
                for medicine in medicines:
                    confidence = self.calculate_name_confidence(medicine_info['brand_name'], medicine.brand_name)
                    if confidence > 0.7:
                        results.append({
                            'medicine': medicine,
                            'confidence_score': confidence,
                            'matched_text': medicine.brand_name,
                            'match_type': 'brand_name'
                        })

            # Strategy 3: Search by generic name
            if medicine_info['generic_name']:
                medicines = self.medicine_service.search_medicines(db, medicine_info['generic_name'], limit)
                for medicine in medicines:
                    confidence = self.calculate_name_confidence(medicine_info['generic_name'], medicine.generic_name)
                    if confidence > 0.7:
                        results.append({
                            'medicine': medicine,
                            'confidence_score': confidence,
                            'matched_text': medicine.generic_name,
                            'match_type': 'generic_name'
                        })

            # Strategy 4: Search by manufacturer
            if medicine_info['manufacturer']:
                medicines = self.medicine_service.search_medicines(db, medicine_info['manufacturer'], limit)
                for medicine in medicines:
                    confidence = self.calculate_name_confidence(medicine_info['manufacturer'], medicine.manufacturer)
                    if confidence > 0.8:
                        results.append({
                            'medicine': medicine,
                            'confidence_score': confidence * 0.8,  # Lower weight for manufacturer matches
                            'matched_text': medicine.manufacturer,
                            'match_type': 'manufacturer'
                        })

            # Strategy 5: Fuzzy search on the entire text
            all_medicines = self.medicine_service.get_medicines(db, limit=100)
            for medicine in all_medicines:
                # Calculate overall similarity
                brand_similarity = fuzz.partial_ratio(text.lower(), medicine.brand_name.lower())
                generic_similarity = fuzz.partial_ratio(text.lower(), medicine.generic_name.lower())
                manufacturer_similarity = fuzz.partial_ratio(text.lower(), medicine.manufacturer.lower())
                
                max_similarity = max(brand_similarity, generic_similarity, manufacturer_similarity)
                
                if max_similarity > 70:
                    results.append({
                        'medicine': medicine,
                        'confidence_score': max_similarity / 100,
                        'matched_text': self.get_best_match(text, medicine),
                        'match_type': 'fuzzy'
                    })

            # Remove duplicates and sort by confidence
            unique_results = self.remove_duplicate_results(results)
            unique_results.sort(key=lambda x: x['confidence_score'], reverse=True)
            
            return unique_results[:limit]

        except Exception as e:
            logger.error(f"Error searching medicines by OCR text: {e}")
            return []

    def calculate_name_confidence(self, extracted_name: str, database_name: str) -> float:
        """Calculate confidence score for name matching"""
        try:
            if not extracted_name or not database_name:
                return 0.0

            # Exact match
            if extracted_name.lower() == database_name.lower():
                return 1.0

            # Partial match
            if extracted_name.lower() in database_name.lower() or database_name.lower() in extracted_name.lower():
                return 0.9

            # Fuzzy match
            similarity = fuzz.ratio(extracted_name.lower(), database_name.lower())
            return similarity / 100

        except Exception as e:
            logger.error(f"Error calculating name confidence: {e}")
            return 0.0

    def get_best_match(self, text: str, medicine: Medicine) -> str:
        """Get the best matching text from medicine"""
        try:
            text_lower = text.lower()
            
            # Check which field has the best match
            brand_score = fuzz.partial_ratio(text_lower, medicine.brand_name.lower())
            generic_score = fuzz.partial_ratio(text_lower, medicine.generic_name.lower())
            manufacturer_score = fuzz.partial_ratio(text_lower, medicine.manufacturer.lower())
            
            scores = [
                (brand_score, medicine.brand_name),
                (generic_score, medicine.generic_name),
                (manufacturer_score, medicine.manufacturer)
            ]
            
            best_match = max(scores, key=lambda x: x[0])
            return best_match[1]

        except Exception as e:
            logger.error(f"Error getting best match: {e}")
            return medicine.brand_name

    def remove_duplicate_results(self, results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Remove duplicate medicine results"""
        try:
            seen_medicines = set()
            unique_results = []
            
            for result in results:
                medicine_id = result['medicine'].id
                if medicine_id not in seen_medicines:
                    seen_medicines.add(medicine_id)
                    unique_results.append(result)
            
            return unique_results

        except Exception as e:
            logger.error(f"Error removing duplicate results: {e}")
            return results

    def process_image_file(self, image_file) -> Tuple[str, Dict[str, Any]]:
        """Process an uploaded image file"""
        try:
            # Read image file
            image_bytes = image_file.read()
            
            # Convert to numpy array
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if image is None:
                raise ValueError("Could not decode image")

            # Extract text
            extracted_text = self.extract_text_from_image(image)
            
            # Extract medicine information
            medicine_info = self.extract_medicine_info(extracted_text)
            
            return extracted_text, medicine_info

        except Exception as e:
            logger.error(f"Error processing image file: {e}")
            return "", {}

    def process_base64_image(self, base64_string: str) -> Tuple[str, Dict[str, Any]]:
        """Process a base64 encoded image"""
        try:
            # Remove data URL prefix if present
            if base64_string.startswith('data:image'):
                base64_string = base64_string.split(',')[1]

            # Decode base64
            image_bytes = base64.b64decode(base64_string)
            
            # Convert to numpy array
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if image is None:
                raise ValueError("Could not decode image")

            # Extract text
            extracted_text = self.extract_text_from_image(image)
            
            # Extract medicine information
            medicine_info = self.extract_medicine_info(extracted_text)
            
            return extracted_text, medicine_info

        except Exception as e:
            logger.error(f"Error processing base64 image: {e}")
            return "", {}

    def enhance_image_quality(self, image: np.ndarray) -> np.ndarray:
        """Enhance image quality for better OCR results"""
        try:
            # Convert to LAB color space
            lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
            
            # Split channels
            l, a, b = cv2.split(lab)
            
            # Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            l = clahe.apply(l)
            
            # Merge channels
            enhanced_lab = cv2.merge([l, a, b])
            
            # Convert back to BGR
            enhanced_image = cv2.cvtColor(enhanced_lab, cv2.COLOR_LAB2BGR)
            
            return enhanced_image

        except Exception as e:
            logger.error(f"Error enhancing image quality: {e}")
            return image

    def detect_text_regions(self, image: np.ndarray) -> List[Tuple[int, int, int, int]]:
        """Detect regions in image that likely contain text"""
        try:
            # Convert to grayscale
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Apply edge detection
            edges = cv2.Canny(gray, 50, 150, apertureSize=3)
            
            # Find contours
            contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            
            text_regions = []
            for contour in contours:
                # Get bounding rectangle
                x, y, w, h = cv2.boundingRect(contour)
                
                # Filter by size (remove very small or very large regions)
                if 50 < w < image.shape[1] * 0.8 and 20 < h < image.shape[0] * 0.8:
                    text_regions.append((x, y, w, h))
            
            return text_regions

        except Exception as e:
            logger.error(f"Error detecting text regions: {e}")
            return []

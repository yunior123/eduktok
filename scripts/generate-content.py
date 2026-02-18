#!/usr/bin/env python3
"""
Eduktok Content Generator
Generates JSON structure for units and lessons to import into Firebase
"""

import json
import os
from typing import List, Dict

# Base R2 URL for assets
R2_BASE_URL = "https://assets.eduktok.com/images"

def generate_listening_lesson(unit_num: int, lesson_num: int, topic: str, items: List[Dict]) -> Dict:
    """Generate a listening comprehension lesson"""
    lesson = {
        "id": f"lesson-{unit_num:02d}-{lesson_num:02d}",
        "lessonNumber": lesson_num,
        "unitNumber": unit_num,
        "type": "Listening",
        "audioUrlDict": {},
        "foreModels": [],
        "backModels": []
    }
    
    for idx, item in enumerate(items):
        # Question/prompt (foreModel)
        fore_model = {
            "text": item.get("question", {}),
            "imageUrl": f"{R2_BASE_URL}/unit-{unit_num:02d}/lesson-{lesson_num:02d}/{item.get('image_file', f'question-{idx+1}.png')}"
        }
        lesson["foreModels"].append(fore_model)
        
        # Answer options (backModels)
        for answer in item.get("answers", []):
            back_model = {
                "text": answer.get("text", {}),
                "imageUrl": f"{R2_BASE_URL}/unit-{unit_num:02d}/lesson-{lesson_num:02d}/{answer.get('image_file', '')}",
                "isCorrect": answer.get("is_correct", False)
            }
            lesson["backModels"].append(back_model)
    
    return lesson

def generate_speaking_lesson(unit_num: int, lesson_num: int, topic: str, items: List[Dict]) -> Dict:
    """Generate a speaking practice lesson"""
    lesson = {
        "id": f"lesson-{unit_num:02d}-{lesson_num:02d}",
        "lessonNumber": lesson_num,
        "unitNumber": unit_num,
        "type": "Speaking",
        "audioUrlDict": {},
        "models": []
    }
    
    for idx, item in enumerate(items):
        model = {
            "text": item.get("text", {}),
            "imageUrl": f"{R2_BASE_URL}/unit-{unit_num:02d}/lesson-{lesson_num:02d}/{item.get('image_file', f'speaking-{idx+1}.png')}",
            "targetPhrase": item.get("target_phrase", "")
        }
        lesson["models"].append(model)
    
    return lesson

def generate_unit(unit_num: int, unit_data: Dict) -> Dict:
    """Generate a complete unit with metadata"""
    unit = {
        "unitNumber": unit_num,
        "unitName": f"Unit {unit_num}",
        "title": unit_data.get("title", {"en": f"Unit {unit_num}", "es": f"Unidad {unit_num}"}),
        "imageUrl": f"{R2_BASE_URL}/unit-{unit_num:02d}/unit-cover.png",
        "description": unit_data.get("description", ""),
        "totalLessons": len(unit_data.get("lessons", []))
    }
    
    return unit

# Example unit structure template
UNIT_TEMPLATE = {
    "unit": 1,
    "title": {
        "en": "Basic Colors",
        "es": "Colores Básicos"
    },
    "description": {
        "en": "Learn to identify and name basic colors",
        "es": "Aprende a identificar y nombrar colores básicos"
    },
    "lessons": [
        {
            "lesson_number": 1,
            "type": "Listening",
            "topic": "Red Objects",
            "items": [
                {
                    "question": {
                        "en": "What color is this apple?",
                        "es": "¿De qué color es esta manzana?"
                    },
                    "image_file": "apple-red.png",
                    "answers": [
                        {
                            "text": {"en": "Red", "es": "Rojo"},
                            "image_file": "color-red.png",
                            "is_correct": True
                        },
                        {
                            "text": {"en": "Blue", "es": "Azul"},
                            "image_file": "color-blue.png",
                            "is_correct": False
                        },
                        {
                            "text": {"en": "Green", "es": "Verde"},
                            "image_file": "color-green.png",
                            "is_correct": False
                        }
                    ]
                }
            ]
        },
        {
            "lesson_number": 2,
            "type": "Speaking",
            "topic": "Pronouncing Colors",
            "items": [
                {
                    "text": {
                        "en": "Say: Red",
                        "es": "Di: Rojo"
                    },
                    "image_file": "color-red-card.png",
                    "target_phrase": "red"
                }
            ]
        }
    ]
}

def main():
    """Main function to generate sample content"""
    print("Eduktok Content Generator")
    print("=" * 50)
    
    # Generate sample unit
    unit_data = UNIT_TEMPLATE
    unit = generate_unit(unit_data["unit"], unit_data)
    
    lessons = []
    for lesson_data in unit_data["lessons"]:
        if lesson_data["type"] == "Listening":
            lesson = generate_listening_lesson(
                unit_data["unit"],
                lesson_data["lesson_number"],
                lesson_data["topic"],
                lesson_data["items"]
            )
        elif lesson_data["type"] == "Speaking":
            lesson = generate_speaking_lesson(
                unit_data["unit"],
                lesson_data["lesson_number"],
                lesson_data["topic"],
                lesson_data["items"]
            )
        lessons.append(lesson)
    
    # Output directory
    output_dir = "./content-output"
    os.makedirs(output_dir, exist_ok=True)
    
    # Save unit
    with open(f"{output_dir}/unit-{unit_data['unit']:02d}.json", "w") as f:
        json.dump(unit, f, indent=2, ensure_ascii=False)
    
    # Save lessons
    for lesson in lessons:
        lesson_num = lesson["lessonNumber"]
        with open(f"{output_dir}/unit-{unit_data['unit']:02d}-lesson-{lesson_num:02d}.json", "w") as f:
            json.dump(lesson, f, indent=2, ensure_ascii=False)
    
    print(f"\n✓ Generated {len(lessons)} lessons for Unit {unit_data['unit']}")
    print(f"✓ Files saved to: {output_dir}/")
    print("\nNext steps:")
    print("1. Review generated JSON files")
    print("2. Create corresponding images in app-images/ directory")
    print("3. Upload images using: ./scripts/upload-to-r2.sh")
    print("4. Import JSON files to Firebase Firestore")

if __name__ == "__main__":
    main()

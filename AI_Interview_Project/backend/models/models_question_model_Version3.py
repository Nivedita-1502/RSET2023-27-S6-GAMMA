"""
Question dataset model for loading and managing interview questions.
"""

import pandas as pd
import random
from typing import List, Optional, Dict
from config_Version3 import Config
import logging
import re

logger = logging.getLogger(__name__)

class QuestionDataset:
    """Load and manage the interview questions dataset from XLSX"""
    
    def __init__(self, xlsx_path: str = Config.DATASET_PATH):
        """
        Initialize the dataset from Excel file.
        
        Args:
            xlsx_path: Path to the Excel file
        """
        try:
            # Read from the first sheet
            self.df = pd.read_excel(xlsx_path)
            self.validate_dataset()
            logger.info(f"✓ Dataset loaded: {len(self.df)} questions")
            logger.info(f"  Columns: {list(self.df.columns)}")
        except FileNotFoundError:
            raise Exception(f"Dataset not found at {xlsx_path}")
        except Exception as e:
            raise Exception(f"Error loading dataset: {str(e)}")
    
    def validate_dataset(self):
        """Validate that required columns exist and clean data"""
        # Convert column names to lowercase for case-insensitive matching
        self.df.columns = self.df.columns.str.lower().str.strip()
        
        required_cols = ['subject', 'difficulty', 'keywords', 'ideal_answer', 'question_text']
        missing = [col for col in required_cols if col not in self.df.columns]
        
        if missing:
            available = list(self.df.columns)
            raise ValueError(
                f"Missing columns: {missing}. Available columns: {available}"
            )
        
        # Remove rows with null values in required columns
        initial_count = len(self.df)
        self.df = self.df.dropna(subset=required_cols)
        removed = initial_count - len(self.df)
        
        if removed > 0:
            logger.warning(f"  Removed {removed} rows with missing values")
        
        # Convert to lowercase for consistency
        self.df['subject'] = self.df['subject'].str.lower().str.strip()
        self.df['difficulty'] = self.df['difficulty'].str.lower().str.strip()
    
    def get_question(self, subject: str, difficulty: str) -> Optional[Dict]:
        """
        Get a random question for given subject and difficulty.
        
        Args:
            subject: Subject (dbms, dsa, os)
            difficulty: Difficulty level (easy, medium, hard)
            
        Returns:
            Dictionary with question details or None if not found
        """
        subject = subject.lower().strip()
        difficulty = difficulty.lower().strip()
        
        filtered = self.df[
            (self.df['subject'] == subject) &
            (self.df['difficulty'] == difficulty)
        ]
        
        if filtered.empty:
            logger.warning(f"No question found for {subject} - {difficulty}")
            return None
        
        # Get random question
        question = filtered.sample(1).iloc[0]
        return {
            'question': str(question['question_text']).strip(),
            'subject': str(question['subject']).strip(),
            'difficulty': str(question['difficulty']).strip(),
            'keywords': str(question['keywords']).strip(),
            'ideal_answer': str(question['ideal_answer']).strip()
        }
    
    def get_available_subjects(self) -> List[str]:
        """Get list of available subjects in dataset"""
        return sorted(self.df['subject'].unique().tolist())
    
    def get_available_difficulties(self, subject: str = None) -> List[str]:
        """
        Get list of available difficulties.
        
        Args:
            subject: Optional subject to filter by
            
        Returns:
            List of difficulty levels
        """
        if subject:
            filtered = self.df[self.df['subject'] == subject.lower()]
            return sorted(filtered['difficulty'].unique().tolist())
        return sorted(self.df['difficulty'].unique().tolist())
    
    def get_subject_difficulty_distribution(self) -> Dict:
        """Get distribution of questions by subject and difficulty"""
        distribution = {}
        for subject in self.get_available_subjects():
            distribution[subject] = {}
            for difficulty in self.get_available_difficulties(subject):
                count = len(self.df[
                    (self.df['subject'] == subject) &
                    (self.df['difficulty'] == difficulty)
                ])
                distribution[subject][difficulty] = count
        return distribution
    
    def get_next_difficulty(self, current_difficulty: str, score: float, subject: str = None) -> str:
        """
        Adaptively determine next difficulty based on answer quality and subject.
        
        Args:
            current_difficulty: Current difficulty level
            score: Similarity score (0-1)
            subject: Subject for threshold customization (optional)
            
        Returns:
            Next difficulty level
        """
        difficulties = ['easy', 'medium', 'hard']
        
        if current_difficulty not in difficulties:
            current_difficulty = 'easy'
        
        current_idx = difficulties.index(current_difficulty)
        
        # Get subject-specific thresholds for difficulty progression
        if subject and subject.upper() in Config.SUBJECT_THRESHOLDS:
            thresholds = Config.SUBJECT_THRESHOLDS[subject.upper()]
            correct_threshold = thresholds['correct']
            partial_threshold = thresholds['partial']
        else:
            # Use default thresholds for DBMS and unknown subjects
            correct_threshold = Config.SIMILARITY_THRESHOLD_CORRECT
            partial_threshold = Config.SIMILARITY_THRESHOLD_PARTIAL
        
        if score >= correct_threshold:  # Use subject-specific threshold
            # Increase difficulty
            return difficulties[min(current_idx + 1, len(difficulties) - 1)]
        elif score >= partial_threshold:  # Partially correct
            # Keep same difficulty
            return current_difficulty
        else:  # Incorrect
            # Decrease difficulty
            return difficulties[max(current_idx - 1, 0)]
    
    def get_next_difficulty_by_classification(self, current_difficulty: str, classification: str) -> str:
        """
        Adaptively determine next difficulty based on answer classification.
        
        Args:
            current_difficulty: Current difficulty level
            classification: Answer classification (correct, partial, incorrect)
            
        Returns:
            Next difficulty level
        """
        difficulties = ['easy', 'medium', 'hard']
        
        if current_difficulty not in difficulties:
            current_difficulty = 'easy'
        
        current_idx = difficulties.index(current_difficulty)
        
        if classification == 'correct':
            # Increase difficulty
            return difficulties[min(current_idx + 1, len(difficulties) - 1)]
        elif classification == 'partial':
            # Keep same difficulty
            return current_difficulty
        else:  # incorrect
            # Decrease difficulty
            return difficulties[max(current_idx - 1, 0)]
    
    def get_statistics(self) -> Dict:
        """Get dataset statistics"""
        return {
            'total_questions': len(self.df),
            'subjects': self.get_available_subjects(),
            'distribution': self.get_subject_difficulty_distribution(),
            'total_by_subject': self.df['subject'].value_counts().to_dict(),
            'total_by_difficulty': self.df['difficulty'].value_counts().to_dict()
        }
"""
Answer evaluators using Sentence Transformers.
Includes:
- Bi-encoder evaluator (embedding + cosine similarity)
- Cross-encoder evaluator (pairwise scoring)
"""

from sentence_transformers import SentenceTransformer, util, CrossEncoder
import numpy as np
from config_Version3 import Config
from typing import Dict, List, Tuple
import torch
import os
import logging

# Import subject-specific evaluator
from train_subject_specific_models import SubjectSpecificEvaluator

logger = logging.getLogger(__name__)


class AnswerEvaluator:
    """
    Evaluate user answers using fine-tuned Sentence Transformers.
    Supports both pre-trained and fine-tuned models.
    """
    
    def __init__(self, model_path: str = None, use_finetuned: bool = True):
        """
        Initialize the embedding model.
        
        Args:
            model_path: Path to custom model or None to use default
            use_finetuned: If True, try to use fine-tuned model, fallback to base
        """
        if model_path is None:
            if use_finetuned and os.path.exists(Config.MODEL_SAVE_PATH):
                model_path = Config.MODEL_SAVE_PATH
                print(f"✓ Loading fine-tuned model: {model_path}")
            else:
                model_path = Config.BASE_MODEL
                print(f"✓ Loading base model: {model_path}")
        
        try:
            self.model = SentenceTransformer(model_path)
            self.model_name = model_path
            print(f"✓ Embedding model loaded successfully")
            print(f"  Model: {self.model_name}")
            print(f"  Dimensions: {self.model.get_sentence_embedding_dimension()}")
        except Exception as e:
            logger.error(f"Error loading model: {e}")
            print(f"✗ Error loading model. Using base model as fallback.")
            self.model = SentenceTransformer(Config.BASE_MODEL)
            self.model_name = Config.BASE_MODEL
    
    def get_embeddings(self, texts: list) -> np.ndarray:
        """
        Get sentence embeddings for texts.
        
        Args:
            texts: List of text strings
            
        Returns:
            Array of embeddings
        """
        if isinstance(texts, str):
            texts = [texts]
        
        embeddings = self.model.encode(
            texts,
            convert_to_tensor=False,
            show_progress_bar=False
        )
        return embeddings
    
    def calculate_similarity(self, user_answer: str, ideal_answer: str) -> float:
        """
        Calculate cosine similarity between user and ideal answer.
        
        Args:
            user_answer: User's provided answer
            ideal_answer: Ideal answer from dataset
            
        Returns:
            Similarity score between 0 and 1
        """
        # Clean answers
        user_answer = user_answer.strip()
        ideal_answer = ideal_answer.strip()
        
        # Encode both answers
        user_emb = self.model.encode(user_answer, convert_to_tensor=True)
        ideal_emb = self.model.encode(ideal_answer, convert_to_tensor=True)
        
        # Cosine similarity (0 to 1 range)
        similarity = util.pytorch_cos_sim(user_emb, ideal_emb)
        return float(similarity[0][0])
    
    def evaluate_answer(self, user_answer: str, ideal_answer: str, subject: str = None) -> Dict:
        """
        Evaluate answer and classify as correct, partial, or incorrect.
        
        Args:
            user_answer: User's answer
            ideal_answer: Ideal answer from dataset
            subject: Subject for threshold customization (optional)
            
        Returns:
            Dictionary with evaluation results
        """
        
        # Clean answers
        user_answer = user_answer.strip()
        ideal_answer = ideal_answer.strip()
        
        # Check for empty answer
        if not user_answer:
            return {
                'similarity_score': 0.0,
                'classification': 'incorrect',
                'points': 0.0,
                'feedback': '✗ No answer provided. Please write your answer.',
                'model_used': self.model_name
            }
        
        # Calculate similarity
        similarity_score = self.calculate_similarity(user_answer, ideal_answer)
        
        # Get subject-specific thresholds
        if subject and subject in Config.SUBJECT_THRESHOLDS:
            thresholds = Config.SUBJECT_THRESHOLDS[subject]
            correct_threshold = thresholds['correct']
            partial_threshold = thresholds['partial']
        else:
            # Use default thresholds
            correct_threshold = Config.SIMILARITY_THRESHOLD_CORRECT
            partial_threshold = Config.SIMILARITY_THRESHOLD_PARTIAL
        
        # Classification logic based on thresholds
        if similarity_score >= correct_threshold:
            classification = "correct"
            points = 1.0
        elif similarity_score >= partial_threshold:
            classification = "partial"
            points = 0.5
        else:
            classification = "incorrect"
            points = 0.0
        
        return {
            'similarity_score': round(similarity_score, 4),
            'classification': classification,
            'points': points,
            'feedback': self._generate_feedback(classification, similarity_score),
            'model_used': self.model_name
        }
    
    def evaluate_batch(self, user_answers: List[str], ideal_answers: List[str]) -> List[Dict]:
        """
        Evaluate multiple answers at once (more efficient).
        
        Args:
            user_answers: List of user answers
            ideal_answers: List of ideal answers
            
        Returns:
            List of evaluation results
        """
        results = []
        
        for user_ans, ideal_ans in zip(user_answers, ideal_answers):
            results.append(self.evaluate_answer(user_ans, ideal_ans))
        
        return results
    
    def _generate_feedback(self, classification: str, score: float) -> str:
        """
        Generate feedback based on classification and score.
        
        Args:
            classification: 'correct', 'partial', or 'incorrect'
            score: Similarity score
            
        Returns:
            Feedback string
        """
        if classification == "correct":
            return "✓ Excellent! Your answer is correct."
        elif classification == "partial":
            return "~ Partially correct. Try to include more key concepts and details."
        else:
            return "✗ Incorrect. Review the ideal answer and key concepts."
    
    def get_model_info(self) -> Dict:
        """Get information about the current model"""
        return {
            'model_name': self.model_name,
            'embedding_dimension': self.model.get_sentence_embedding_dimension(),
            'max_seq_length': self.model.get_max_seq_length(),
            'is_finetuned': 'fine_tuned' in self.model_name,
            'thresholds': {
                'correct': Config.SIMILARITY_THRESHOLD_CORRECT,
                'partial': Config.SIMILARITY_THRESHOLD_PARTIAL
            }
        }


class CrossEncoderAnswerEvaluator:
    """
    Evaluate user answers using a Cross-Encoder.
    The model takes (user_answer, ideal_answer) pairs and returns a similarity score.
    """

    def __init__(self, model_name: str = None):
        """
        If a fine-tuned local evaluator exists at Config.LOCAL_EVALUATOR_MODEL_PATH,
        use that. Otherwise, fall back to a generic public cross-encoder.
        """
        if model_name is None:
            if os.path.exists(Config.LOCAL_EVALUATOR_MODEL_PATH):
                model_name = Config.LOCAL_EVALUATOR_MODEL_PATH
            else:
                model_name = "cross-encoder/ms-marco-MiniLM-L-6-v2"

        try:
            print(f"✓ Loading cross-encoder model: {model_name}")
            self.model = CrossEncoder(model_name)
            self.model_name = model_name
        except Exception as e:
            logger.error(f"Error loading cross-encoder model: {e}")
            # Fallback to the bi-encoder so the API still works
            print("✗ Error loading cross-encoder. Falling back to embedding model.")
            self.model = SentenceTransformer(Config.BASE_MODEL)
            self.model_name = Config.BASE_MODEL

    def calculate_similarity(self, user_answer: str, ideal_answer: str) -> float:
        """
        Calculate similarity score using the cross-encoder.
        Returns a score in [0, 1] (normalized when necessary).
        """
        user_answer = user_answer.strip()
        ideal_answer = ideal_answer.strip()

        # If we accidentally fell back to a SentenceTransformer, use cosine similarity
        if isinstance(self.model, SentenceTransformer):
            user_emb = self.model.encode(user_answer, convert_to_tensor=True)
            ideal_emb = self.model.encode(ideal_answer, convert_to_tensor=True)
            similarity = util.pytorch_cos_sim(user_emb, ideal_emb)
            return float(similarity[0][0])

        score = float(self.model.predict([(user_answer, ideal_answer)])[0])

        # Some cross-encoders output scores on arbitrary scales (e.g. [-5, 5] or [0, 5]).
        # First normalise obvious 0–5 style scores, then clamp to [0, 1] so that
        # thresholds and percentage formatting always make sense.
        if score > 1.0:
            score = score / 5.0

        # Clamp to [0, 1] to avoid negative values or >100% percentages in the UI
        score = max(0.0, min(1.0, score))

        return score

    def evaluate_answer(self, user_answer: str, ideal_answer: str, subject: str = None) -> Dict:
        """
        Evaluate answer and classify as correct, partial, or incorrect
        using the cross-encoder similarity score.
        """
        user_answer = user_answer.strip()
        ideal_answer = ideal_answer.strip()

        if not user_answer:
            return {
                'similarity_score': 0.0,
                'classification': 'incorrect',
                'points': 0.0,
                'feedback': '✗ No answer provided. Please write your answer.',
                'model_used': self.model_name
            }

        similarity_score = self.calculate_similarity(user_answer, ideal_answer)

        # Get subject-specific thresholds
        if subject and subject in Config.SUBJECT_THRESHOLDS:
            thresholds = Config.SUBJECT_THRESHOLDS[subject]
            correct_threshold = thresholds['correct']
            partial_threshold = thresholds['partial']
        else:
            # Use default thresholds
            correct_threshold = Config.SIMILARITY_THRESHOLD_CORRECT
            partial_threshold = Config.SIMILARITY_THRESHOLD_PARTIAL

        if similarity_score >= correct_threshold:
            classification = "correct"
            points = 1.0
        elif similarity_score >= partial_threshold:
            classification = "partial"
            points = 0.5
        else:
            classification = "incorrect"
            points = 0.0

        return {
            'similarity_score': round(similarity_score, 4),
            'classification': classification,
            'points': points,
            'feedback': self._generate_feedback(classification, similarity_score),
            'model_used': self.model_name
        }

    def _generate_feedback(self, classification: str, score: float) -> str:
        if classification == "correct":
            return "✓ Excellent! Your answer is correct."
        elif classification == "partial":
            return "~ Partially correct. Try to include more key concepts and details."
        else:
            return "✗ Incorrect. Review the ideal answer and key concepts."

    def evaluate_batch(self, user_answers: List[str], ideal_answers: List[str]) -> List[Dict]:
        results = []
        for user_ans, ideal_ans in zip(user_answers, ideal_answers):
            results.append(self.evaluate_answer(user_ans, ideal_ans))
        return results

    def get_model_info(self) -> Dict:
        dim = getattr(self.model, "get_sentence_embedding_dimension", lambda: None)()
        return {
            'model_name': self.model_name,
            'embedding_dimension': dim,
            'is_cross_encoder': True,
            'thresholds': {
                'correct': Config.SIMILARITY_THRESHOLD_CORRECT,
                'partial': Config.SIMILARITY_THRESHOLD_PARTIAL
            }
        }
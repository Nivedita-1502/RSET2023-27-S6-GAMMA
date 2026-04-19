"""
Evaluation routes for AI Interview System
Handles answer evaluation and difficulty progression
"""

import logging
import re
from flask import Blueprint, request, jsonify
from models.models_answer_evaluator_Version3 import AnswerEvaluator
from models.models_question_model_Version3 import QuestionDataset
from config_Version3 import Config
from models.models_answer_evaluator_Version3 import SubjectSpecificEvaluator

# Create blueprint
evaluation_bp = Blueprint('evaluation', __name__, url_prefix='/api/evaluation')

# Initialize global variables
dataset = None
evaluator = None
dbms_evaluator = None
subject_evaluator = None

def init_evaluation_routes():
    """Initialize evaluation routes with dataset and evaluators"""
    global dataset, evaluator, dbms_evaluator, subject_evaluator
    
    # Load dataset
    dataset = QuestionDataset(Config.DATASET_PATH)
    
    # Initialize evaluators
    evaluator = AnswerEvaluator(Config.EMBEDDING_MODEL)
    dbms_evaluator = AnswerEvaluator(Config.FINETUNED_MODEL_PATH)  # Use fine-tuned model for DBMS
    subject_evaluator = SubjectSpecificEvaluator()  # Use subject-specific evaluators for OS/DSA
    
    logging.info("Evaluation routes initialized")

def _simple_tokenize(text):
    """Simple tokenization by splitting on whitespace and punctuation."""
    if not text:
        return []
    # Split on whitespace and common punctuation
    tokens = re.split(r'[\s,.;:!?()]+', text.strip())
    return [token for token in tokens if token]

def _looks_like_keyword_list(answer, keywords):
    """Check if answer looks like just a list of keywords with fillers."""
    if not keywords:
        return False
    
    answer_lower = answer.lower()
    keywords_lower = keywords.lower()
    keyword_list = [kw.strip() for kw in keywords_lower.split(',')]
    
    # Common filler words that don't add meaning
    filler_words = {
        'is', 'are', 'was', 'were', 'be', 'been', 'being',
        'a', 'an', 'the', 'this', 'that', 'these', 'those',
        'at', 'in', 'on', 'for', 'with', 'by', 'from', 'to',
        'and', 'or', 'but', 'so', 'because', 'if', 'when',
        'it', 'they', 'them', 'their', 'its', 'his', 'her',
        'used', 'use', 'using', 'can', 'will', 'would', 'could',
        'has', 'have', 'had', 'do', 'does', 'did'
    }
    
    # Count how many keywords appear in the answer
    keyword_matches = sum(1 for kw in keyword_list if kw in answer_lower)
    
    # Tokenize and analyze
    tokens = _simple_tokenize(answer)
    if len(tokens) <= 1:
        return False
    
    # Count meaningful tokens (non-filler, non-keyword)
    meaningful_tokens = [
        token for token in tokens 
        if token not in filler_words and token not in keyword_list
    ]
    
    # Calculate ratios
    keyword_ratio = keyword_matches / len(tokens) if tokens else 0
    filler_ratio = sum(1 for token in tokens if token in filler_words) / len(tokens) if tokens else 0
    
    # Consider it keyword list if:
    # 1. High keyword ratio (>50%)
    # 2. Low meaningful content (<3 meaningful tokens)
    # 3. High filler ratio + some keywords
    is_keyword_list = (
        (keyword_ratio > 0.5) or 
        (len(meaningful_tokens) < 3 and keyword_matches >= 2) or
        (filler_ratio > 0.4 and keyword_matches >= 2)
    )
    
    return is_keyword_list

@evaluation_bp.route('/submit-answer', methods=['POST'])
def submit_answer():
    """
    Evaluate a user's answer against the ideal answer.
    
    Request JSON:
        - user_answer: str (the user's answer)
        - ideal_answer: str (the correct answer)
        - keywords: str (comma-separated keywords)
        - subject: str (subject for subject-specific evaluation)
    
    Response:
        - success: bool
        - evaluation: dict with similarity_score, classification, points, feedback
    """
    try:
        if evaluator is None:
            return jsonify({
                'success': False,
                'message': 'Evaluator not initialized'
            }), 500
        
        data = request.get_json()
        user_answer = data.get('user_answer', '').strip()
        ideal_answer = data.get('ideal_answer', '').strip()
        keywords = data.get('keywords', '').strip()
        subject = data.get('subject', '').strip()
        
        # Validate inputs
        if not user_answer:
            return jsonify({
                'success': False,
                'message': 'User answer is required'
            }), 400
        
        if not ideal_answer:
            return jsonify({
                'success': False,
                'message': 'Ideal answer is required'
            }), 400
        
        logger = logging.getLogger(__name__)
        logger.info(f"Evaluating answer (length: {len(user_answer)} chars)")
        
        # Choose evaluator based on subject
        if subject and subject.upper() == 'DBMS':
            # Use original evaluator for DBMS but with improved logic
            evaluation = dbms_evaluator.evaluate_answer(user_answer, ideal_answer, subject)
            
            # Apply DBMS-specific improvements
            if evaluation['classification'] == 'incorrect' and evaluation['similarity_score'] >= 0.45:
                # Boost borderline cases to partial
                evaluation['classification'] = 'partial'
                evaluation['points'] = 0.5
                evaluation['feedback'] = "Partial. Your answer shows some understanding but could be more complete."
            elif evaluation['classification'] == 'partial' and evaluation['similarity_score'] >= 0.52:
                # Boost strong partial answers to correct
                evaluation['classification'] = 'correct'
                evaluation['points'] = 1.0
                evaluation['feedback'] = "Correct! Good understanding of the concept."
        else:
            # Use subject-specific evaluator for OS and DSA
            evaluation = subject_evaluator.evaluate_answer(user_answer, ideal_answer, subject)

        # Apply strict keyword detection for all subjects
        is_keyword_list = _looks_like_keyword_list(user_answer, keywords)
        if is_keyword_list:
            # For all subjects (OS, DSA, DBMS), treat keyword-only answers as incorrect
            if subject and subject.upper() == 'DBMS':
                # Slightly more lenient for DBMS - allow partial credit if similarity is decent
                if evaluation['similarity_score'] >= 0.40:
                    evaluation['classification'] = 'partial'
                    evaluation['points'] = 0.5
                    evaluation['feedback'] = (
                        "Partial. Your answer looks like a keyword list. "
                        "Please provide more explanation in full sentences."
                    )
                else:
                    evaluation['classification'] = 'incorrect'
                    evaluation['points'] = 0.0
                    evaluation['feedback'] = (
                        "Incorrect. Your answer looks like a keyword list. "
                        "Please explain in full sentences."
                    )
            else:
                # Strict for OS and DSA - always incorrect for keyword lists
                evaluation['classification'] = 'incorrect'
                evaluation['points'] = 0.0
                evaluation['feedback'] = (
                    "Incorrect. Your answer looks like a keyword list. "
                    "Please explain in full sentences."
                )
        elif evaluation['classification'] == 'correct' and len(_simple_tokenize(user_answer)) < 8:
            # Very short answers shouldn't be full credit even if similarity is high
            evaluation['classification'] = 'partial'
            evaluation['points'] = 0.5
            evaluation['feedback'] += " Provide a bit more detail to receive full credit."
        
        logger.info(f"  Classification: {evaluation['classification']}")
        logger.info(f"  Similarity: {evaluation['similarity_score']}")
        
        return jsonify({
            'success': True,
            'evaluation': evaluation
        }), 200
    
    except Exception as e:
        logger = logging.getLogger(__name__)
        logger.error(f"Error in submit_answer: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@evaluation_bp.route('/batch-evaluate', methods=['POST'])
def batch_evaluate():
    """
    Evaluate multiple answers at once (more efficient).
    
    Request JSON:
        - answers: list of dicts with user_answer and ideal_answer
    
    Response:
        - evaluations: list of evaluation results
    """
    try:
        if evaluator is None:
            return jsonify({
                'success': False,
                'message': 'Evaluator not initialized'
            }), 500
        
        data = request.get_json()
        answers = data.get('answers', [])
        
        if not answers:
            return jsonify({
                'success': False,
                'message': 'No answers provided'
            }), 400
        
        evaluations = []
        for answer_data in answers:
            user_answer = answer_data.get('user_answer', '').strip()
            ideal_answer = answer_data.get('ideal_answer', '').strip()
            keywords = answer_data.get('keywords', '').strip()
            subject = answer_data.get('subject', '').strip()
            
            if user_answer and ideal_answer:
                if subject and subject.upper() == 'DBMS':
                    evaluation = dbms_evaluator.evaluate_answer(user_answer, ideal_answer, subject)
                else:
                    evaluation = subject_evaluator.evaluate_answer(user_answer, ideal_answer, subject)
                evaluations.append(evaluation)
        
        return jsonify({
            'success': True,
            'evaluations': evaluations
        }), 200
    
    except Exception as e:
        logger = logging.getLogger(__name__)
        logger.error(f"Error in batch_evaluate: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@evaluation_bp.route('/get-next-difficulty', methods=['POST'])
def get_next_difficulty():
    """
    Get the next difficulty level based on answer performance.
    
    Request JSON:
        - current_difficulty: str (easy, medium, hard)
        - classification: str (correct, partial, incorrect)
        - subject: str (optional, for subject-specific thresholds)
    
    Response:
        - next_difficulty: str
    """
    try:
        if dataset is None:
            return jsonify({
                'success': False,
                'message': 'Dataset not initialized'
            }), 500
        
        data = request.get_json()
        current_difficulty = data.get('current_difficulty', '').lower().strip()
        classification = data.get('classification', '').lower().strip()
        subject = data.get('subject', '').strip()
        
        # Validate inputs
        if not current_difficulty:
            return jsonify({
                'success': False,
                'message': 'Current difficulty is required'
            }), 400
        
        if classification not in ['correct', 'partial', 'incorrect']:
            return jsonify({
                'success': False,
                'message': 'Classification must be correct, partial, or incorrect'
            }), 400
        
        logger = logging.getLogger(__name__)
        logger.info(f"Difficulty progression: {current_difficulty} (classification: {classification}, subject: {subject})")
        
        # Use classification-based adaptive logic
        next_difficulty = dataset.get_next_difficulty_by_classification(current_difficulty, classification)
        
        logger.info(f"Next difficulty: {next_difficulty}")
        
        return jsonify({
            'success': True,
            'next_difficulty': next_difficulty
        }), 200
    except Exception as e:
        logger = logging.getLogger(__name__)
        logger.error(f"Error in get_next_difficulty: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@evaluation_bp.route('/calculate-stats', methods=['POST'])
def calculate_stats():
    """
    Calculate statistics from evaluation results.
    
    Request JSON:
        - results: list of evaluation results
    
    Response:
        - stats: dict with various statistics
    """
    try:
        data = request.get_json()
        results = data.get('results', [])
        
        if not results:
            return jsonify({
                'success': False,
                'message': 'No results provided'
            }), 400
        
        # Calculate statistics
        total = len(results)
        correct = sum(1 for r in results if r.get('classification') == 'correct')
        partial = sum(1 for r in results if r.get('classification') == 'partial')
        incorrect = sum(1 for r in results if r.get('classification') == 'incorrect')
        
        # Calculate average similarity score
        similarity_scores = [r.get('similarity_score', 0) for r in results if r.get('similarity_score') is not None]
        avg_similarity = sum(similarity_scores) / len(similarity_scores) if similarity_scores else 0
        
        # Calculate total points
        total_points = sum(r.get('points', 0) for r in results)
        max_points = total * 1.0
        percentage = (total_points / max_points * 100) if max_points > 0 else 0
        
        stats = {
            'total_questions': total,
            'correct': correct,
            'partial': partial,
            'incorrect': incorrect,
            'accuracy_percentage': round(percentage, 2),
            'average_similarity': round(avg_similarity, 4),
            'total_points': round(total_points, 2),
            'max_points': max_points
        }
        
        return jsonify({
            'success': True,
            'stats': stats
        }), 200
    
    except Exception as e:
        logger = logging.getLogger(__name__)
        logger.error(f"Error in calculate_stats: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500
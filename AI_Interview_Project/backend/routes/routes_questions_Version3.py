"""
Flask routes for question endpoints.
Handles fetching questions and quiz information.
"""

from flask import Blueprint, request, jsonify
from models.models_question_model_Version3 import QuestionDataset
from utils.data_loader import validate_subject, validate_difficulty
import logging

logger = logging.getLogger(__name__)

questions_bp = Blueprint('questions', __name__, url_prefix='/api/questions')

# Initialize dataset once
try:
    dataset = QuestionDataset()
    logger.info("✓ Dataset initialized successfully")
except Exception as e:
    logger.error(f"Error initializing dataset: {e}")
    dataset = None

@questions_bp.route('/get-question', methods=['POST'])
def get_question():
    """
    Get a question based on subject and difficulty.
    
    Request JSON:
        - subject: str (dbms, dsa, os)
        - difficulty: str (easy, medium, hard)
    
    Response:
        - question: str
        - subject: str
        - difficulty: str
        - keywords: str
        - ideal_answer: str (for backend evaluation)
    """
    try:
        if dataset is None:
            return jsonify({
                'success': False,
                'message': 'Dataset not loaded'
            }), 500
        
        data = request.get_json()
        subject = data.get('subject', '').lower().strip()
        difficulty = data.get('difficulty', '').lower().strip()
        
        # Validation
        if not subject:
            available_subjects = dataset.get_available_subjects()
            return jsonify({
                'success': False,
                'message': f'Subject required. Available: {available_subjects}'
            }), 400
        
        if not difficulty:
            available_difficulties = dataset.get_available_difficulties(subject)
            return jsonify({
                'success': False,
                'message': f'Difficulty required. Available for {subject}: {available_difficulties}'
            }), 400
        
        # Get question
        question_data = dataset.get_question(subject, difficulty)
        
        if not question_data:
            available_difficulties = dataset.get_available_difficulties(subject)
            return jsonify({
                'success': False,
                'message': f'No question found for {subject} - {difficulty}. Available: {available_difficulties}'
            }), 404
        
        # Return question without ideal_answer to frontend
        response_data = {
            'question': question_data['question'],
            'subject': question_data['subject'],
            'difficulty': question_data['difficulty'],
            'keywords': question_data['keywords']
        }
        
        # Include ideal_answer for backend evaluation
        return jsonify({
            'success': True,
            'data': response_data,
            'ideal_answer': question_data['ideal_answer']
        }), 200
    
    except Exception as e:
        logger.error(f"Error in get_question: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@questions_bp.route('/subjects', methods=['GET'])
def get_subjects():
    """Get list of available subjects"""
    try:
        if dataset is None:
            return jsonify({'success': False, 'message': 'Dataset not loaded'}), 500
        
        subjects = dataset.get_available_subjects()
        return jsonify({
            'success': True,
            'subjects': subjects
        }), 200
    except Exception as e:
        logger.error(f"Error in get_subjects: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@questions_bp.route('/difficulties/<subject>', methods=['GET'])
def get_difficulties(subject):
    """Get list of available difficulties for a subject"""
    try:
        if dataset is None:
            return jsonify({'success': False, 'message': 'Dataset not loaded'}), 500
        
        difficulties = dataset.get_available_difficulties(subject)
        if not difficulties:
            return jsonify({
                'success': False,
                'message': f'No difficulties found for subject: {subject}'
            }), 404
        
        return jsonify({
            'success': True,
            'difficulties': difficulties
        }), 200
    except Exception as e:
        logger.error(f"Error in get_difficulties: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@questions_bp.route('/info', methods=['GET'])
def get_quiz_info():
    """Get quiz configuration and statistics"""
    try:
        if dataset is None:
            return jsonify({'success': False, 'message': 'Dataset not loaded'}), 500
        
        from config_Version3 import Config
        
        return jsonify({
            'success': True,
            'quiz_config': {
                'total_questions_per_quiz': Config.TOTAL_QUESTIONS_PER_QUIZ,
                'supported_subjects': dataset.get_available_subjects(),
                'similarity_thresholds': {
                    'correct': Config.SIMILARITY_THRESHOLD_CORRECT,
                    'partial': Config.SIMILARITY_THRESHOLD_PARTIAL
                }
            },
            'dataset_statistics': dataset.get_statistics()
        }), 200
    except Exception as e:
        logger.error(f"Error in get_quiz_info: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@questions_bp.route('/quiz-settings', methods=['GET'])
def get_quiz_settings():
    """
    Get current quiz settings including total questions per quiz.
    """
    try:
        from config_Version3 import Config
        return jsonify({
            'success': True,
            'settings': {
                'total_questions_per_quiz': Config.TOTAL_QUESTIONS_PER_QUIZ,
                'supported_subjects': Config.SUPPORTED_SUBJECTS,
                'supported_difficulties': Config.SUPPORTED_DIFFICULTIES
            }
        }), 200
    except Exception as e:
        logger.error(f"Error in get_quiz_settings: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500


@questions_bp.route('/health', methods=['GET'])
def questions_health():
    """Health check for questions service"""
    try:
        dataset_loaded = dataset is not None
        stats = dataset.get_statistics() if dataset_loaded else {}
        
        return jsonify({
            'success': True,
            'service': 'questions',
            'dataset_loaded': dataset_loaded,
            'total_questions': stats.get('total_questions', 0)
        }), 200
    except Exception as e:
        logger.error(f"Error in questions_health: {e}")
        return jsonify({
            'success': False,
            'service': 'questions',
            'error': str(e)
        }), 500
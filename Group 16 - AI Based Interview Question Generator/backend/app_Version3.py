"""
Main Flask application for AI-Based Adaptive Interview Question Generator.
Integrates fine-tuned Sentence Transformers for answer evaluation.
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
from config_Version3 import Config
from routes.routes_questions_Version3 import questions_bp
from routes.routes_evaluation_Version3 import evaluation_bp
import logging
import os
from datetime import datetime

# Create Flask app
app = Flask(__name__)
app.config.from_object(Config)

# Enable CORS for frontend
CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:3000", "http://localhost:5173", "http://localhost:5000", "127.0.0.1:3000"],
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type"],
        "supports_credentials": True
    }
})

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Register blueprints
app.register_blueprint(questions_bp)
app.register_blueprint(evaluation_bp)

# Initialize evaluation routes
from routes.routes_evaluation_Version3 import init_evaluation_routes
init_evaluation_routes()

# Routes
@app.route('/', methods=['GET'])
def root():
    """Root endpoint with API information"""
    return jsonify({
        'app': 'AI-Based Adaptive Interview Question Generator',
        'version': '1.0.0',
        'timestamp': datetime.now().isoformat(),
        'endpoints': {
            'health': '/api/health',
            'questions': '/api/questions',
            'evaluation': '/api/evaluation'
        },
        'documentation': '/api/docs'
    }), 200

@app.route('/api/health', methods=['GET'])
def health_check():
    """Comprehensive health check for all services"""
    try:
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'services': {
                'api': 'running',
                'questions': 'check /api/questions/health',
                'evaluation': 'check /api/evaluation/health'
            }
        }), 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 500

@app.route('/api/docs', methods=['GET'])
def api_docs():
    """API documentation"""
    return jsonify({
        'app': 'AI-Based Adaptive Interview Question Generator',
        'version': '1.0.0',
        'description': 'Adaptive learning system that evaluates interview answers using fine-tuned Sentence Transformers',
        'endpoints': {
            'questions': {
                'GET /api/questions/subjects': 'Get available subjects',
                'GET /api/questions/difficulties/<subject>': 'Get available difficulties',
                'POST /api/questions/get-question': 'Get a question (body: {subject, difficulty})',
                'GET /api/questions/info': 'Get quiz configuration and statistics',
                'GET /api/questions/health': 'Health check for questions service'
            },
            'evaluation': {
                'POST /api/evaluation/submit-answer': 'Evaluate an answer (body: {user_answer, ideal_answer})',
                'POST /api/evaluation/batch-evaluate': 'Batch evaluate answers',
                'POST /api/evaluation/get-next-difficulty': 'Get next difficulty (body: {current_difficulty, similarity_score})',
                'POST /api/evaluation/calculate-stats': 'Calculate final stats (body: {results})',
                'GET /api/evaluation/model-info': 'Get model information',
                'GET /api/evaluation/health': 'Health check for evaluation service'
            }
        },
        'model': {
            'type': 'Fine-tuned Sentence Transformer',
            'base': Config.BASE_MODEL,
            'finetuned_path': Config.MODEL_SAVE_PATH,
            'training_epochs': Config.TRAINING_EPOCHS,
            'batch_size': Config.TRAINING_BATCH_SIZE
        }
    }), 200

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        'success': False,
        'message': 'Endpoint not found',
        'path': request.path
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    logger.error(f"Internal server error: {error}")
    return jsonify({
        'success': False,
        'message': 'Internal server error',
        'error': str(error)
    }), 500

if __name__ == '__main__':
    logger.info("="*70)
    logger.info("Starting AI-Based Adaptive Interview Question Generator")
    logger.info("="*70)
    logger.info(f"Dataset path: {Config.DATASET_PATH}")
    logger.info(f"Fine-tuned model path: {Config.MODEL_SAVE_PATH}")
    logger.info(f"Debug mode: {Config.DEBUG}")
    logger.info(f"Listening on: http://0.0.0.0:5000")
    logger.info("="*70)
    
    # Create necessary directories
    os.makedirs('data', exist_ok=True)
    os.makedirs('models', exist_ok=True)
    
    # Run app
    app.run(
        debug=Config.DEBUG,
        host='0.0.0.0',
        port=5000,
        threaded=True
    )
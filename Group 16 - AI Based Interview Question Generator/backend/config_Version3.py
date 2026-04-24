import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    """Configuration settings for the application"""
    
    # Flask Settings
    DEBUG = os.getenv('DEBUG', True)
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-2026')
    
    # Data Settings
    DATASET_PATH = os.getenv('DATASET_PATH', 'data/interview_questions_final_cleaned.xlsx')
    TRAINING_DATA_PATH = os.getenv('TRAINING_DATA_PATH', 'data/training_pairs.csv')
    
    # Model Settings
    BASE_MODEL = 'all-MiniLM-L6-v2'  # Base pre-trained model
    FINETUNED_MODEL_PATH = os.getenv('FINETUNED_MODEL_PATH', 'models/fine_tuned_model')
    EMBEDDING_MODEL = FINETUNED_MODEL_PATH if os.path.exists(FINETUNED_MODEL_PATH) else BASE_MODEL
    # Local evaluator (cross-encoder) fine-tuned on LLM-labeled data
    EVAL_DATASET_PATH = os.getenv('EVAL_DATASET_PATH', 'data/eval_dataset_llama.csv')
    LOCAL_EVALUATOR_MODEL_PATH = os.getenv('LOCAL_EVALUATOR_MODEL_PATH', 'models/local_evaluator_crossencoder')
    
    # Similarity Thresholds
    # Note: With cosine similarity on sentence embeddings, good paraphrases often score ~0.60–0.75.
    # Tune these to match your dataset and desired strictness.
    SIMILARITY_THRESHOLD_CORRECT = 0.60  # Lowered from 0.65 for more lenient evaluation
    SIMILARITY_THRESHOLD_PARTIAL = 0.45  # Lowered from 0.50
    
    # Subject-specific thresholds (more lenient for OS/DSA)
    SUBJECT_THRESHOLDS = {
        'dbms': {'correct': 0.55, 'partial': 0.40},  # More lenient thresholds for DBMS
        'DBMS': {'correct': 0.55, 'partial': 0.40},  # Uppercase version
        'os': {'correct': 0.45, 'partial': 0.30},    # More lenient for OS (lowered from 0.55/0.40)
        'OS': {'correct': 0.45, 'partial': 0.30},     # Uppercase version (lowered from 0.55/0.40)
        'dsa': {'correct': 0.55, 'partial': 0.40},    # More lenient for DSA
        'DSA': {'correct': 0.55, 'partial': 0.40}     # Uppercase version
    }
    
    # Quiz Settings
    TOTAL_QUESTIONS_PER_QUIZ = int(os.getenv('TOTAL_QUESTIONS_PER_QUIZ', '3'))  # Default 3, configurable
    SUPPORTED_SUBJECTS = ['dbms', 'dsa', 'os']
    SUPPORTED_DIFFICULTIES = ['easy', 'medium', 'hard']
    
    # Training Settings
    TRAINING_BATCH_SIZE = 16
    TRAINING_EPOCHS = 4
    WARMUP_STEPS = 500
    MODEL_SAVE_PATH = 'models/fine_tuned_model'
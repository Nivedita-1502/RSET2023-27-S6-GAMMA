import pandas as pd
from config_Version3 import Config

def load_dataset():
    """Load the interview questions dataset"""
    try:
        df = pd.read_csv(Config.DATASET_PATH)
        print(f"✓ Dataset loaded: {len(df)} questions")
        return df
    except FileNotFoundError:
        raise Exception(f"Dataset not found at {Config.DATASET_PATH}")

def validate_subject(subject: str) -> bool:
    """Validate if subject is supported"""
    return subject.lower() in Config.SUPPORTED_SUBJECTS

def validate_difficulty(difficulty: str) -> bool:
    """Validate if difficulty is supported"""
    return difficulty.lower() in Config.SUPPORTED_DIFFICULTIES
import pandas as pd
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, ".."))
DATA_PATH = os.path.join(PROJECT_ROOT, "data", "wlb_score_dataset.csv")
df = pd.read_csv(DATA_PATH)

for col in df.columns:
    print(f"\nColumn: {col}")
    print("Unique Count:", df[col].nunique())
    print("Values:", df[col].unique())
print("=== FEATURE ANALYSIS SCRIPT STARTED ===")

import pandas as pd

print("Library imported")

# Load preprocessed data
df = pd.read_csv("preprocessed_employee_data.csv")

print("Preprocessed dataset loaded")
print("Shape:", df.shape)

# Correlation analysis
correlation = df.corr()

print("\nCorrelation Matrix:")
print(correlation)

print("\nFeature analysis completed successfully")

print("=== FEATURE ANALYSIS SCRIPT COMPLETED ===")

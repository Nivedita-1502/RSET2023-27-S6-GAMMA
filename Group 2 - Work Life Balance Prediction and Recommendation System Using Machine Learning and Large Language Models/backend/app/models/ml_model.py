print("=== ML MODEL MODULE LOADED ===")

import pandas as pd
import numpy as np
import os

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from sklearn.ensemble import RandomForestRegressor

# -------------------------------------------------
# Paths
# -------------------------------------------------

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, "..", ".."))

DATA_PATH = os.path.join(PROJECT_ROOT, "data", "processed_wlb_dataset.csv")

# -------------------------------------------------
# Load Dataset
# -------------------------------------------------

df = pd.read_csv(DATA_PATH)

print("Dataset loaded:", df.shape)

# -------------------------------------------------
# Range mappings
# -------------------------------------------------

range_maps = {

"hours_worked":{"<35":32,"35-40":38,"40-45":43,"45-50":48,">50":55},

"overtime_hours":{"None":0,"1-5":3,"6-10":8,"11-15":13,">15":18},

"projects_handled":{"1":1,"2-3":3,"4-5":5,"6-8":7,">8":9},

"meetings_count":{"0-5":3,"6-10":8,"11-15":13,"16-20":18,">20":25},

"breaks":{"None":0,"1":1,"2":2,"3":3,"4+":4},

"family_time":{"<3":2,"3-5":4,"6-10":8,"11-15":12,">15":16},

"break_duration":{"<10":5,"10-20":15,"20-30":25,"30-45":35,">45":50},

"commute_time":{"No commute":0,"<30":20,"30-60":45,"1-2h":90,">2h":150},

"sick_days":{"None":0,"1":1,"2":2,"3":3,"4+":4},

"leave_days":{"None":0,"1":1,"2":2,"3":3,"4+":4},

"travel":{"No travel":0,"1 trip":1,"2 trips":2,"3 trips":3,">3 trips":4},

"task_delay":{"Never":0,"Rarely":1,"Sometimes":2,"Often":3,"Always":4}

}

for col, mapping in range_maps.items():
    if col in df.columns:
        df[col] = df[col].map(mapping)

# -------------------------------------------------
# Features
# -------------------------------------------------

features = [

"hours_worked",
"overtime_hours",
"projects_handled",
"meetings_count",
"workload_rating",
"deadline_pressure",
"productivity_rating",
"task_delay",
"breaks",
"break_duration",
"sick_days",
"leave_days",
"exhaustion_rating",
"travel",
"travel_enjoyment",
"family_time",
"social_satisfaction",
"commute_time"

]

X = df[features]
y = df["wlb_score"]   # already 0-100 scaled

# -------------------------------------------------
# Scaling
# -------------------------------------------------

scaler = MinMaxScaler()

X_scaled = scaler.fit_transform(X)

# -------------------------------------------------
# Train Test Split
# -------------------------------------------------

X_train, X_test, y_train, y_test = train_test_split(
    X_scaled,
    y,
    test_size=0.2,
    random_state=42
)

# -------------------------------------------------
# Model
# -------------------------------------------------

model = RandomForestRegressor(
    n_estimators=400,
    max_depth=18,
    min_samples_split=4,
    random_state=42
)

model.fit(X_train, y_train)

r2 = model.score(X_test, y_test)

print("Model trained")
print("R2 score:", round(r2, 3))

# -------------------------------------------------
# Feature Importance
# -------------------------------------------------

feature_importance = pd.Series(
    model.feature_importances_,
    index=features
).sort_values(ascending=False)

print("Top Influencing Factors:")
print(feature_importance.head(10))

# -------------------------------------------------
# Label Logic
# -------------------------------------------------

def score_to_label(score):

    if score < 40:
        return "POOR"
    elif score < 70:
        return "MODERATE"
    else:
        return "GOOD"

# -------------------------------------------------
# Prediction
# -------------------------------------------------

def predict_wlb(user_data: dict):

    sample = pd.DataFrame([user_data])

    for col, mapping in range_maps.items():
        if col in sample.columns:
            sample[col] = sample[col].map(mapping)

    sample_scaled = scaler.transform(sample)

    predicted_score = model.predict(sample_scaled)[0]

    predicted_score = round(predicted_score,2)

    label = score_to_label(predicted_score)

    confidence = round(model.score(X_test, y_test) * 100, 2)

    return {
        "wlb_score": predicted_score,
        "wlb_label": label,
        "confidence": confidence
    }
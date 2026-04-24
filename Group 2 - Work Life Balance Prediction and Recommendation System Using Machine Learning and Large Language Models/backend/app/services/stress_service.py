# app/services/wlb_score_service.py

from app.models.ml_model import predict_wlb

def get_wlb_analysis(user_data):

    # Predict label using ML
    prediction = predict_wlb(user_data)

    return {
        "wlb_score": prediction["wlb_score"],
        "wlb_label": prediction["wlb_label"],
        "confidence": prediction["confidence"]
    }
# app/services/rag_service.py

from app.rag.rag_engine import generate_recommendation

def get_recommendations(user_data, wlb_label, wlb_score):
    
    recommendations = generate_recommendation(
        user_data,
        wlb_label,
        wlb_score
    )

    return recommendations
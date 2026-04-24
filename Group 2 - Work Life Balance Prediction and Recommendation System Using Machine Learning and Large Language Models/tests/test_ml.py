from app.models.ml_model import predict_wlb

# Sample employee input
user_input = {

    "hours_worked": "45-50",
    "overtime_hours": "11-15",
    "projects_handled": "6-8",
    "meetings_count": "11-15",

    "workload_rating": 4,
    "deadline_pressure": 4,

    "productivity_rating": 3,
    "task_delay": "Sometimes",

    "breaks": "1",
    "break_duration": "10-20",

    "sick_days": "1",
    "leave_days": "1",

    "exhaustion_rating": 4,

    "travel": "1 trip",
    "travel_enjoyment": 3,

    "family_time": "3-5",
    "social_satisfaction": 3,

    "commute_time": "30-60"
}

# Run prediction
result = predict_wlb(user_input)

print("Predicted Work-Life Balance:", result["wlb_label"])
print("Confidence:", result["confidence"], "%")

from app.services.stress_service import get_wlb_analysis

user = {

    "hours_worked": "45-50",
    "overtime_hours": "11-15",
    "projects_handled": "6-8",
    "meetings_count": "11-15",

    "workload_rating": 4,
    "deadline_pressure": 4,

    "productivity_rating": 3,
    "task_delay": "Sometimes",

    "breaks": "1",
    "break_duration": "10-20",

    "sick_days": "1",
    "leave_days": "1",

    "exhaustion_rating": 4,

    "travel": "1 trip",
    "travel_enjoyment": 3,

    "family_time": "3-5",
    "social_satisfaction": 3,

    "commute_time": "30-60"
}

result = get_wlb_analysis(user)

print(result)
# app/main.py

from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from datetime import datetime, timedelta
from fastapi.middleware.cors import CORSMiddleware

from app.models.schemas import (
    UserSignup,
    UserProfile,
    WeeklyCheckin
)

from app.services.stress_service import get_wlb_analysis
from app.services.llm_service import generate_recommendations
from app.services.chatbot_service import chatbot_stream

from app.database.mongo import (
    users_collection,
    weekly_logs_collection,
    wlb_results_collection
)

from app.database.mongo import chat_collection
from datetime import datetime

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# =========================
# JWT CONFIG
# =========================

SECRET_KEY = "supersecretkey"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

security = HTTPBearer()


def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):

    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("email")

        if email is None:
            raise HTTPException(status_code=401, detail="Invalid token")

        return email

    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")


# =========================
# SIGNUP
# =========================

@app.post("/signup")
def signup(user: UserSignup):

    existing_user = users_collection.find_one({"email": user.email})

    if existing_user:
        raise HTTPException(status_code=400, detail="User already exists")

    users_collection.insert_one({
        "name": user.name,
        "age": user.age,
        "email": user.email,
        "password": user.password,
        "created_at": datetime.utcnow()
    })

    token = create_access_token({"email": user.email})

    return {"message": "User created successfully",
            "access_token": token,
            "token_type": "bearer"
    }


# =========================
# LOGIN
# =========================

from pydantic import BaseModel

class LoginInput(BaseModel):
    email: str
    password: str


@app.post("/login")
def login(user: LoginInput):

    existing_user = users_collection.find_one({"email": user.email})

    if not existing_user:
        raise HTTPException(status_code=400, detail="User not found")

    if existing_user["password"] != user.password:
        raise HTTPException(status_code=400, detail="Incorrect password")

    token = create_access_token({"email": user.email})

    return {
        "message": "Login successful",
        "access_token": token,
        "token_type": "bearer"
    }


# =========================
# PROFILE QUESTIONNAIRE
# =========================

@app.post("/profile-setup")
def profile_setup(
    profile: UserProfile,
    current_user: str = Depends(get_current_user)
):

    if current_user != profile.email:
        raise HTTPException(status_code=403, detail="Unauthorized")

    users_collection.update_one(
        {"email": profile.email},
        {"$set": profile.dict()}
    )

    return {"message": "Profile saved successfully"}


# =========================
# WEEKLY CHECKIN
# =========================
@app.post("/weekly-checkin")
def weekly_checkin(
    data: WeeklyCheckin,
    current_user: str = Depends(get_current_user)
):

    if current_user != data.email:
        raise HTTPException(status_code=403, detail="Unauthorized")

    user = users_collection.find_one({"email": data.email})

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # ------------------------------------------------
    # Prepare ML Model Input
    # ------------------------------------------------
    break_map = {
        "Less than 10 minutes":"<10",
        "10 – 20 minutes":"10-20",
        "20 – 30 minutes":"20-30",
        "30 – 45 minutes":"30-45",
        "More than 45 minutes":">45"
        }

    travel_map = {
        "No travel":"No travel",
        "1 trip":"1 trip",
        "2 trips":"2 trips",
        "3 trips":"3 trips",
        "More than 3 trips":">3 trips"
        }
    ml_input = {
        "hours_worked": data.hours_worked,
        "overtime_hours": data.overtime_hours,
        "projects_handled": data.projects_handled,
        "meetings_count": data.meetings_count,

        "workload_rating": data.workload_rating,
        "deadline_pressure": data.deadline_pressure,

        "productivity_rating": data.productivity_rating,
        "task_delay": data.task_delay,

        "breaks": data.breaks,
        "break_duration": break_map[data.break_duration],


        "sick_days": data.sick_days,
        "leave_days": data.leave_days,
        "exhaustion_rating": data.exhaustion_rating,

        "travel": travel_map[data.travel],
        "travel_enjoyment": data.travel_enjoyment,

        "family_time": data.family_time,
        "social_satisfaction": data.social_satisfaction,

        # From profile setup
        "commute_time": user.get("commute_time")
    }

    # ------------------------------------------------
    # ML Prediction
    # ------------------------------------------------

    wlb_result = get_wlb_analysis(ml_input)

    # ------------------------------------------------
    # LLM Recommendation Input
    # ------------------------------------------------

    llm_input = {

        # Profile info
        "name": user.get("name"),
        "age": user.get("age"),
        "department": user.get("department"),
        "role_level": user.get("role_level"),
        "work_mode": user.get("work_mode"),
        "commute_time": user.get("commute_time"),

        # Weekly checkin
        **data.dict(),

        # ML output
        "wlb_score": wlb_result["wlb_score"],
        "wlb_label": wlb_result["wlb_label"],
        "confidence": wlb_result["confidence"]
    }

    ai_output = generate_recommendations(llm_input)

    # ------------------------------------------------
    # Save Weekly Log
    # ------------------------------------------------
    checklist_items = [
    {"task": item, "completed": False}
    for item in ai_output.get("weekly_checklist", [])
    ]

    weekly_logs_collection.insert_one({
        "email": data.email,
        **data.dict(),
        "wlb_score": wlb_result["wlb_score"],
        "wlb_label": wlb_result["wlb_label"],
        "confidence": wlb_result["confidence"],
        "recommendations": ai_output.get("recommendations"),
        "weekly_checklist": checklist_items,   
        "created_at": datetime.utcnow()
    })

    # Store ML result separately

    wlb_results_collection.insert_one({
        "email": data.email,
        "wlb_score": wlb_result["wlb_score"],
        "wlb_label": wlb_result["wlb_label"],
        "confidence": wlb_result["confidence"],
        "created_at": datetime.utcnow()
    })

    # ------------------------------------------------
    # API Response
    # ------------------------------------------------

    return {
        "wlb_score": wlb_result["wlb_score"],
        "wlb_label": wlb_result["wlb_label"],
        "confidence": wlb_result["confidence"],
        "recommendations": ai_output.get("recommendations"),
        "weekly_checklist": ai_output.get("weekly_checklist")
    }


# =========================
# WLB TREND
# =========================

@app.get("/wlb-trend")
def wlb_trend(current_user: str = Depends(get_current_user)):

    logs = list(
        weekly_logs_collection
        .find({"email": current_user})
        .sort("created_at", 1)
    )

    if len(logs) < 2:
        return {
            "message": "Not enough data to calculate trend",
            "data_points": len(logs)
        }

    scores = [log["wlb_score"] for log in logs]

    current_score = scores[-1]
    previous_score = scores[-2]

    change = round(current_score - previous_score, 2)

    if change > 0:
        trend = "Improving"
    elif change < 0:
        trend = "Declining"
    else:
        trend = "Stable"

    return {
        "current_wlb_score": current_score,
        "previous_wlb_score": previous_score,
        "change": change,
        "trend": trend,
        "total_weeks_tracked": len(scores),
        "last_5_weeks": scores[-5:]
    }

# =========================
# GET DASHBOARD DATA
# =========================

@app.get("/dashboard")
def get_dashboard(current_user: str = Depends(get_current_user)):

    latest_log = weekly_logs_collection.find_one(
        {"email": current_user},
        sort=[("created_at", -1)]
    )

    if not latest_log:
        return {
            "message": "No weekly check-in found. Please complete your first check-in."
        }

    # get last 5 logs for trend
    last_logs = list(
        weekly_logs_collection.find(
            {"email": current_user}
        ).sort("created_at", -1).limit(5)
    )

    scores = [log["wlb_score"] for log in reversed(last_logs)]

    current_score = scores[-1]
    previous_score = scores[-2] if len(scores) > 1 else None

    trend = "Stable"
    change = 0

    if previous_score:
        change = current_score - previous_score
        if change > 0:
            trend = "Improving"
        elif change < 0:
            trend = "Declining"

    return {
        "log_id": str(latest_log["_id"]),
        "wlb_score": latest_log["wlb_score"],
        "wlb_label": latest_log["wlb_label"],
        "confidence": latest_log["confidence"],

        "recommendations": latest_log.get("recommendations", []),

        "weekly_checklist": [
            item["task"] for item in latest_log.get("weekly_checklist", [])
        ],

        "current_wlb_score": current_score,
        "previous_wlb_score": previous_score,
        "trend": trend,
        "change": change,
        "last_5_weeks": scores,

        "last_updated": latest_log["created_at"]
    }

from bson import ObjectId

# =========================
# UPDATE CHECKLIST ITEM
# =========================

@app.put("/update-checklist")
def update_checklist(
    log_id: str,
    index: int,
    completed: bool,
    current_user: str = Depends(get_current_user)
):

    log = weekly_logs_collection.find_one({"_id": ObjectId(log_id)})

    if not log:
        raise HTTPException(status_code=404, detail="Log not found")

    if log["email"] != current_user:
        raise HTTPException(status_code=403, detail="Unauthorized")

    weekly_logs_collection.update_one(
        {"_id": ObjectId(log_id)},
        {
            "$set": {
                f"weekly_checklist.{index}.completed": completed
            }
        }
    )

    return {"message": "Checklist updated"}

from pydantic import BaseModel

class ChatInput(BaseModel):
    message: str


from fastapi.responses import StreamingResponse
from app.services.chatbot_service import chatbot_stream
import json

@app.post("/chatbot")
def chatbot(
    chat: ChatInput,
    current_user: str = Depends(get_current_user)
):

    user = users_collection.find_one({"email": current_user})

    chat_collection.insert_one({
        "email": current_user,
        "role": "user",
        "message": chat.message,
        "created_at": datetime.utcnow()
    })

    history = list(
        chat_collection
        .find({"email": current_user})
        .sort("created_at", -1)
        .limit(10)
    )

    history.reverse()

    conversation = ""

    for msg in history:
        if msg["role"] == "user":
            conversation += f"User: {msg['message']}\n"
        else:
            conversation += f"Assistant: {msg['message']}\n"

    latest_log = weekly_logs_collection.find_one(
        {"email": current_user},
        sort=[("created_at",-1)]
    )

    wlb_score = latest_log["wlb_score"] if latest_log else "unknown"

    prompt = f"""
You are a friendly AI coach helping users improve work‑life balance.

IMPORTANT RULES:
- Only answer the user's latest message.
- Do NOT repeat the prompt.
- Do NOT repeat conversation history.
- Do NOT include labels like "User:", "Assistant:", "Latest WLB score:", or "User profile:".
- Give short supportive advice (3‑6 sentences or numbered tips).

User profile:
Name: {user.get("name")}
Age: {user.get("age")}
Work mode: {user.get("work_mode")}

Conversation history:
{conversation}

Latest WLB score: {wlb_score}

User message:
{chat.message}

Assistant response:
"""

    def generate():

        full_reply = ""

        for chunk in chatbot_stream(prompt):

            # remove prompt leakage
            bad_phrases = [
                "User:",
                "Assistant:",
                "Latest WLB",
                "User profile",
                "Conversation history"
            ]

            if any(bad in chunk for bad in bad_phrases):
                continue

            full_reply += chunk
            yield chunk

        chat_collection.insert_one({
            "email": current_user,
            "role": "ai",
            "message": full_reply,
            "created_at": datetime.utcnow()
        })

    return StreamingResponse(generate(), media_type="text/plain")

# =========================
# DELETE ACCOUNT
# =========================

@app.delete("/delete-account")
def delete_account(current_user: str = Depends(get_current_user)):

    users_collection.delete_one({"email": current_user})
    weekly_logs_collection.delete_many({"email": current_user})
    wlb_results_collection.delete_many({"email": current_user})

    return {"message": "Account deleted successfully"}

# =========================
# GET USER PROFILE
# =========================

@app.get("/profile")
def get_profile(current_user: str = Depends(get_current_user)):

    user = users_collection.find_one(
        {"email": current_user},
        {"_id": 0, "password": 0}
    )

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user
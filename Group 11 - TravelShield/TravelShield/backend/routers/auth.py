"""
routers/auth.py  -  User authentication: signup, login, profile.
Security: bcrypt password hashing, JWT tokens, rate limiting.
Updated for PostgreSQL — uses %s instead of ?
"""

import re
from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from core.database import get_db
from core.security import (
    hash_password, verify_password,
    create_access_token, decode_token,
    check_rate_limit, record_failed_attempt, clear_failed_attempts
)

router   = APIRouter(tags=["Auth"])
security = HTTPBearer()


# ── Auth dependency ───────────────────────────────────────────────────────────

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    email = decode_token(token)
    if not email:
        raise HTTPException(status_code=401, detail="Invalid or expired token.")
    return email


# ── Password validator ────────────────────────────────────────────────────────

def validate_password(password: str):
    if len(password) < 8:
        return "Password must be at least 8 characters."
    if not re.search(r'[A-Z]', password):
        return "Must include an uppercase letter."
    if not re.search(r'[0-9]', password):
        return "Must include a number."
    if not re.search(r'[#@!$%^&*]', password):
        return "Must include a special character (#@!$%^&*)."
    return None


# ── Signup ────────────────────────────────────────────────────────────────────

@router.post("/signup")
def signup(data: dict):
    try:
        if not re.match(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$', data["email"]):
            return {"status": "error", "message": "Please enter a valid email address."}

        error = validate_password(data["password"])
        if error:
            return {"status": "error", "message": error}

        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT 1 FROM users WHERE email=%s", (data["email"],))
            if cursor.fetchone():
                return {"status": "error", "message": "An account with this email already exists."}

            hashed = hash_password(data["password"])

            cursor.execute("""
            INSERT INTO users(
                first_name, middle_name, last_name, gender, dob, phone,
                emergency_contact, nationality, address, blood_group,
                email, password, created_at
            ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                data["first_name"], data["middle_name"], data["last_name"],
                data["gender"], data["dob"], data["phone"],
                data["emergency_contact"], data["nationality"],
                data["address"], data["blood_group"],
                data["email"], hashed,
                datetime.now().isoformat()
            ))
        return {"status": "success", "message": "User registered successfully"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


# ── Login ─────────────────────────────────────────────────────────────────────

@router.post("/login")
def login(data: dict):
    try:
        email    = data.get("email", "").strip()
        password = data.get("password", "")

        blocked, wait_minutes = check_rate_limit(email)
        if blocked:
            return {
                "status": "error",
                "message": f"Too many failed attempts. Try again in {wait_minutes} minute(s)."
            }

        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
            user = cursor.fetchone()

        if user and verify_password(password, user[12]):
            clear_failed_attempts(email)
            token = create_access_token({"sub": email})
            return {
                "status": "success",
                "token":  token,
                "user":   _row_to_user(user)
            }

        record_failed_attempt(email)
        return {"status": "error", "message": "Invalid email or password."}

    except Exception as e:
        return {"status": "error", "message": str(e)}


# ── Profile (protected) ───────────────────────────────────────────────────────

@router.get("/profile/{email}")
def get_profile(email: str, current_user: str = Depends(get_current_user)):
    if current_user != email:
        raise HTTPException(status_code=403, detail="Access denied.")
    try:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
            user = cursor.fetchone()
        if not user:
            return {"status": "error", "message": "User not found"}
        return {"status": "success", "user": _row_to_user(user)}
    except Exception as e:
        return {"status": "error", "message": str(e)}


# ── Update Profile (protected) ────────────────────────────────────────────────

@router.patch("/profile/{email}")
def update_profile(email: str, data: dict, current_user: str = Depends(get_current_user)):
    if current_user != email:
        raise HTTPException(status_code=403, detail="Access denied.")
    try:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE users
                SET phone=%s, emergency_contact=%s, address=%s
                WHERE email=%s
            """, (
                data.get("phone"),
                data.get("emergency_contact"),
                data.get("address"),
                email
            ))
        return {"status": "success", "message": "Profile updated"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


# ── Delete Account (protected) ────────────────────────────────────────────────

@router.delete("/account")
def delete_account(current_user: str = Depends(get_current_user)):
    try:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                DELETE FROM itinerary_days WHERE trip_id IN (
                    SELECT id FROM trips WHERE user_email=%s
                )
            """, (current_user,))
            cursor.execute("DELETE FROM trips WHERE user_email=%s", (current_user,))
            cursor.execute("DELETE FROM login_attempts WHERE email=%s", (current_user,))
            cursor.execute("DELETE FROM users WHERE email=%s", (current_user,))
        return {"status": "success", "message": "Account deleted successfully."}
    except Exception as e:
        return {"status": "error", "message": str(e)}


# ── Helper ────────────────────────────────────────────────────────────────────

def _row_to_user(row):
    return {
        "first_name":        row[1],  "middle_name":     row[2],
        "last_name":         row[3],  "gender":          row[4],
        "dob":               row[5],  "phone":           row[6],
        "emergency_contact": row[7],  "nationality":     row[8],
        "address":           row[9],  "blood_group":     row[10],
        "email":             row[11],
    }
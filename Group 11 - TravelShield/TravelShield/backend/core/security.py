"""
core/security.py  –  Password hashing, JWT tokens, rate limiting.
Updated for PostgreSQL — uses %s instead of ?
"""

from datetime import datetime, timedelta
from passlib.context import CryptContext
from jose import JWTError, jwt
from core.database import get_db
import os

# ── Config ────────────────────────────────────────────────────────────────────
# IMPORTANT: Change SECRET_KEY before deploying!
# Generate: python -c "import secrets; print(secrets.token_hex(32))"
SECRET_KEY = os.getenv("SECRET_KEY", "")
ALGORITHM          = "HS256"
TOKEN_EXPIRE_HOURS = 24

MAX_ATTEMPTS    = 5
LOCKOUT_MINUTES = 15

# ── Password hashing ──────────────────────────────────────────────────────────
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


# ── JWT tokens ────────────────────────────────────────────────────────────────

def create_access_token(data: dict) -> str:
    payload = data.copy()
    payload["exp"] = datetime.utcnow() + timedelta(hours=TOKEN_EXPIRE_HOURS)
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def decode_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None


# ── Rate limiting (PostgreSQL) ────────────────────────────────────────────────

def check_rate_limit(email: str):
    with get_db() as conn:
        cursor = conn.cursor()
        cutoff = (datetime.utcnow() - timedelta(minutes=LOCKOUT_MINUTES)).isoformat()
        cursor.execute("""
            SELECT COUNT(*) FROM login_attempts
            WHERE email=%s AND attempted_at > %s AND success=0
        """, (email, cutoff))
        count = cursor.fetchone()[0]

    if count >= MAX_ATTEMPTS:
        return True, LOCKOUT_MINUTES
    return False, 0

def record_failed_attempt(email: str):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO login_attempts (email, attempted_at, success)
            VALUES (%s, %s, 0)
        """, (email, datetime.utcnow().isoformat()))

def clear_failed_attempts(email: str):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM login_attempts WHERE email=%s", (email,))
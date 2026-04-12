"""
routers/otp.py  –  Email OTP generation and verification for signup.
"""

import os
import random
import smtplib
import string
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from fastapi import APIRouter
from core.config import logger

router = APIRouter(tags=["OTP"])

# ── Config ────────────────────────────────────────────────────────────────────
EMAIL_ADDRESS  = os.getenv("EMAIL_ADDRESS", "")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD", "")

# ── In-memory OTP store: {email: {"otp": "123456", "expires": datetime}} ──────
_otp_store: dict = {}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _generate_otp() -> str:
    return ''.join(random.choices(string.digits, k=6))


def _send_email(to_email: str, otp: str) -> bool:
    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = "TravelShield — Your Verification Code"
        msg["From"]    = EMAIL_ADDRESS
        msg["To"]      = to_email

        html = f"""
        <html>
        <body style="font-family: Arial, sans-serif; background: #f5f6f8; padding: 40px;">
          <div style="max-width: 480px; margin: auto; background: white;
                      border-radius: 20px; padding: 40px; box-shadow: 0 4px 20px rgba(0,0,0,0.08);">
            <div style="text-align: center; margin-bottom: 24px;">
              <div style="font-size: 32px;">🛡️</div>
              <h2 style="color: #1A6B3C; margin: 8px 0;">TravelShield</h2>
              <p style="color: #9EB5A8; font-size: 13px;">God's Own Country — Safe & Smart Travel</p>
            </div>
            <p style="color: #0D1B12; font-size: 15px;">Your verification code is:</p>
            <div style="background: #EEF5F1; border-radius: 14px; padding: 24px;
                        text-align: center; margin: 20px 0;">
              <span style="font-size: 42px; font-weight: 800; color: #1A6B3C;
                           letter-spacing: 10px;">{otp}</span>
            </div>
            <p style="color: #9EB5A8; font-size: 13px;">
              This code expires in <strong>10 minutes</strong>.<br>
              If you did not request this, please ignore this email.
            </p>
            <hr style="border: none; border-top: 1px solid #f0f4f2; margin: 24px 0;">
            <p style="color: #9EB5A8; font-size: 11px; text-align: center;">
              TravelShield — Kerala Tourism Safety Platform
            </p>
          </div>
        </body>
        </html>
        """

        msg.attach(MIMEText(html, "html"))

        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.sendmail(EMAIL_ADDRESS, to_email, msg.as_string())

        return True
    except Exception as e:
        logger.error(f"Email send failed: {e}")
        return False


# ── Routes ────────────────────────────────────────────────────────────────────

@router.post("/otp/send")
def send_otp(data: dict):
    """Generate and send OTP to email."""
    email = data.get("email", "").strip().lower()
    if not email:
        return {"status": "error", "message": "Email is required"}

    if not EMAIL_ADDRESS or not EMAIL_PASSWORD:
        return {"status": "error", "message": "Email service not configured"}

    otp     = _generate_otp()
    expires = datetime.now() + timedelta(minutes=10)

    _otp_store[email] = {"otp": otp, "expires": expires}

    success = _send_email(email, otp)
    if success:
        logger.info(f"OTP sent to {email}")
        return {"status": "success", "message": f"OTP sent to {email}"}
    else:
        return {"status": "error", "message": "Failed to send OTP. Check email configuration."}


@router.post("/otp/verify")
def verify_otp(data: dict):
    """Verify OTP entered by user."""
    email = data.get("email", "").strip().lower()
    otp   = data.get("otp", "").strip()

    if not email or not otp:
        return {"status": "error", "message": "Email and OTP are required"}

    record = _otp_store.get(email)
    if not record:
        return {"status": "error", "message": "No OTP found for this email. Please request again."}

    if datetime.now() > record["expires"]:
        del _otp_store[email]
        return {"status": "error", "message": "OTP has expired. Please request a new one."}

    if record["otp"] != otp:
        return {"status": "error", "message": "Invalid OTP. Please try again."}

    # OTP verified — remove from store
    del _otp_store[email]
    return {"status": "success", "message": "Email verified successfully"}
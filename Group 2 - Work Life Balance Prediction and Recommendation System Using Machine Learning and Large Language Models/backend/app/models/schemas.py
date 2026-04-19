from pydantic import BaseModel, EmailStr
from typing import Optional
from enum import Enum

# -------------------------------------------------
# ENUMS
# -------------------------------------------------

class AgeGroup(str, Enum):
    a1 = "18-25"
    a2 = "26-35"
    a3 = "36-45"
    a4 = "46-55"
    a5 = "55+"


class MaritalStatus(str, Enum):
    single = "Single"
    married = "Married"
    divorced = "Divorced / Separated"
    widowed = "Widowed"
    prefer_not = "Prefer not to say"


class Children(str, Enum):
    none = "No children"
    one = "1 child"
    two = "2 children"
    three_plus = "3 or more children"


class WorkMode(str, Enum):
    wfh = "Work From Home"
    hybrid = "Hybrid"
    office = "Office Only"


class CommuteTime(str, Enum):
    none = "No commute (Work From Home)"
    short = "Less than 30 minutes"
    medium = "30 – 60 minutes"
    long = "1 – 2 hours"
    extreme = "More than 2 hours"


class TaskDelay(str, Enum):
    never = "Never"
    rarely = "Rarely"
    sometimes = "Sometimes"
    often = "Often"
    always = "Always"


class BreakDuration(str, Enum):
    very_short = "Less than 10 minutes"
    short = "10 – 20 minutes"
    medium = "20 – 30 minutes"
    long = "30 – 45 minutes"
    extended = "More than 45 minutes"


class TravelType(str, Enum):
    none = "No travel"
    one = "1 trip"
    two = "2 trips"
    three = "3 trips"
    many = "More than 3 trips"


# -------------------------------------------------
# 1️⃣ User Signup
# -------------------------------------------------

class UserSignup(BaseModel):
    name: str
    age: int
    email: EmailStr
    password: str


# -------------------------------------------------
# 2️⃣ Profile Setup Questionnaire
# -------------------------------------------------

class UserProfile(BaseModel):

    email: EmailStr

    age_group: AgeGroup
    marital_status: MaritalStatus
    children: Children

    department: str
    role_level: str

    work_mode: WorkMode

    official_work_hours: str

    commute_time: CommuteTime


# -------------------------------------------------
# 3️⃣ Weekly Check‑In Questionnaire
# -------------------------------------------------

class WeeklyCheckin(BaseModel):

    email: EmailStr

    # Workload
    hours_worked: str
    overtime_hours: str
    projects_handled: str
    meetings_count: str

    # Work Pressure
    workload_rating: int
    deadline_pressure: int

    # Productivity
    productivity_rating: int
    task_delay: TaskDelay

    # Breaks
    breaks: str
    break_duration: BreakDuration

    # Health
    sick_days: str
    leave_days: str
    exhaustion_rating: int

    # Travel
    travel: TravelType
    travel_enjoyment: Optional[int] = None

    # Personal Life
    family_time: str
    social_satisfaction: int


# -------------------------------------------------
# 4️⃣ ML Model Input (internal use)
# -------------------------------------------------

class WLBModelInput(BaseModel):

    hours_worked: str
    overtime_hours: str
    projects_handled: str
    meetings_count: str

    workload_rating: int
    deadline_pressure: int

    productivity_rating: int
    task_delay: TaskDelay

    breaks: str
    break_duration: BreakDuration

    sick_days: str
    leave_days: str
    exhaustion_rating: int

    travel: TravelType
    travel_enjoyment: Optional[int]

    family_time: str
    social_satisfaction: int

    commute_time: CommuteTime
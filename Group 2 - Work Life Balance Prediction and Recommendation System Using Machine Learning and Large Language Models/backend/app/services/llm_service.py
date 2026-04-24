from app.rag.rag_engine import generate_recommendation
import requests
import json

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "phi3:mini"


def generate_recommendations(wlb_data: dict) -> dict:
    """
    Calls local Ollama model to generate personalized recommendations
    based on Work-Life Balance analysis and questionnaire inputs.
    """

    # -------------------------------------------------
    # Retrieve RAG Knowledge
    # -------------------------------------------------

    rag_context = generate_recommendation(
        user_data=wlb_data,
        wlb_label=wlb_data.get("wlb_label"),
        wlb_score=wlb_data.get("wlb_score"),
        top_k=4
    )

    # -------------------------------------------------
    # Prompt
    # -------------------------------------------------

    prompt = f"""
You are an AI workplace wellness assistant helping employees improve their work‑life balance.

Use the following expert knowledge when generating advice:

{rag_context}

------------------------------------

User Profile
Name: {wlb_data.get("name", "User")}
Age: {wlb_data.get("age", "Not specified")}
Department: {wlb_data.get("department", "Not specified")}
Role Level: {wlb_data.get("role_level", "Not specified")}
Work Mode: {wlb_data.get("work_mode", "Not specified")}
Commute Time: {wlb_data.get("commute_time", "Not specified")}

------------------------------------

Weekly Work Metrics
Hours Worked: {wlb_data.get("hours_worked")}
Overtime Hours: {wlb_data.get("overtime_hours")}
Projects Handled: {wlb_data.get("projects_handled")}
Meetings Attended: {wlb_data.get("meetings_count")}

Workload Rating: {wlb_data.get("workload_rating")}
Deadline Pressure: {wlb_data.get("deadline_pressure")}
Productivity Rating: {wlb_data.get("productivity_rating")}
Task Delay Frequency: {wlb_data.get("task_delay")}

Breaks Per Day: {wlb_data.get("breaks")}
Break Duration: {wlb_data.get("break_duration")}

Sick Days: {wlb_data.get("sick_days")}
Leave Days: {wlb_data.get("leave_days")}
Exhaustion Level: {wlb_data.get("exhaustion_rating")}

Work Travel: {wlb_data.get("travel")}
Travel Experience: {wlb_data.get("travel_enjoyment")}

Family / Social Time: {wlb_data.get("family_time")}
Social Satisfaction: {wlb_data.get("social_satisfaction")}

------------------------------------

Work-Life Balance Prediction
WLB Score: {wlb_data.get("wlb_score")}
WLB Label: {wlb_data.get("wlb_label")}
Model Confidence: {wlb_data.get("confidence")}

------------------------------------


Instructions



Generate a user-friendly response using bullet-style advice.
Ensure the response is tailored according to the user profile and weekly work matrix.

Recommendations:
- Provide 5 to 8 personalized bullet point recommendations.
- The FIRST bullet must be the encouragement or compliment message.
- Keep advice practical and easy to follow.

Weekly Checklist:
- Provide a simple 5‑item checklist the user can follow this week.

Return the response strictly in JSON format like this:

{{
"recommendations": ["...", "...", "..."],
"weekly_checklist": ["...", "...", "...", "...", "..."]
}}

Return ONLY raw JSON.
Do NOT use markdown.
Do NOT wrap the output in backticks.
Do NOT include explanations.
Output must be valid JSON only.
"""

    # -------------------------------------------------
    # Ollama Request
    # -------------------------------------------------

    payload = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "stream": False
    }

    response = requests.post(OLLAMA_URL, json=payload)

    if response.status_code != 200:
        raise Exception(f"Ollama error: {response.text}")

    result = response.json()

    model_output = result.get("response", "").strip()

    # -------------------------------------------------
    # Clean model output
    # -------------------------------------------------

    if "```" in model_output:
        model_output = model_output.split("```")[1]

    if model_output.lower().startswith("json"):
        model_output = model_output[4:].strip()

    # -------------------------------------------------
    # Parse JSON
    # -------------------------------------------------

    try:
        parsed = json.loads(model_output)
        return parsed

    except json.JSONDecodeError:
        print("⚠ JSON Parsing Failed. Raw Output:")
        print(model_output)

        return {
            "recommendations": [model_output],
            "weekly_checklist": []
        }
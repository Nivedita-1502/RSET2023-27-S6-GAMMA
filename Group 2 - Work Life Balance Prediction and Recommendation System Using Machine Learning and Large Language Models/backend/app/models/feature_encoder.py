def encode_features(data):

    age_map = {
        "18-25": 1,
        "26-35": 2,
        "36-45": 3,
        "46-55": 4,
        "55+": 5
    }

    marital_map = {
        "Single": 1,
        "Married": 2,
        "Divorced": 3,
        "Widowed": 4,
        "Prefer not to say": 5
    }

    children_map = {
        "No children": 0,
        "1 child": 1,
        "2 children": 2,
        "3+ children": 3
    }

    role_map = {
        "Entry Level": 1,
        "Mid Level": 2,
        "Senior Level": 3,
        "Manager / Lead": 4,
        "Executive / Director": 5
    }

    work_mode_map = {
        "Work From Home": 1,
        "Hybrid": 2,
        "Office Only": 3
    }

    official_hours_map = {
        "8-4": 1,
        "9-5": 2,
        "10-6": 3,
        "11-7": 4,
        "Rotational": 5,
        "Night": 6
    }

    commute_map = {
        "No commute": 0,
        "<30": 1,
        "30-60": 2,
        "1-2h": 3,
        ">2h": 4
    }

    hours_worked_map = {
        "<35": 1,
        "35-40": 2,
        "40-45": 3,
        "45-50": 4,
        ">50": 5
    }

    overtime_map = {
        "None": 0,
        "1-5": 1,
        "6-10": 2,
        "11-15": 3,
        ">15": 4
    }

    projects_map = {
        "1": 1,
        "2-3": 2,
        "4-5": 3,
        "6-8": 4,
        ">8": 5
    }

    meetings_map = {
        "0-5": 1,
        "6-10": 2,
        "11-15": 3,
        "16-20": 4,
        ">20": 5
    }

    task_delay_map = {
        "Never": 1,
        "Rarely": 2,
        "Sometimes": 3,
        "Often": 4,
        "Always": 5
    }

    breaks_map = {
        "None": 0,
        "1": 1,
        "2": 2,
        "3": 3,
        "4+": 4
    }

    break_duration_map = {
        "<10": 1,
        "10-20": 2,
        "20-30": 3,
        "30-45": 4,
        ">45": 5
    }

    sick_days_map = {
        "None": 0,
        "1": 1,
        "2": 2,
        "3": 3,
        "4+": 4
    }

    leave_days_map = {
        "None": 0,
        "1": 1,
        "2": 2,
        "3": 3,
        "4+": 4
    }

    travel_map = {
        "No travel": 0,
        "1 trip": 1,
        "2 trips": 2,
        "3 trips": 3,
        ">3 trips": 4
    }

    family_time_map = {
        "<3": 1,
        "3-5": 2,
        "6-10": 3,
        "11-15": 4,
        ">15": 5
    }

    encoded = {

        "age_group": age_map[data["age_group"]],
        "marital_status": marital_map[data["marital_status"]],
        "children": children_map[data["children"]],
        "role_level": role_map[data["role_level"]],

        "official_work_hours": official_hours_map[data["official_work_hours"]],
        "work_mode": work_mode_map[data["work_mode"]],
        "commute_time": commute_map[data["commute_time"]],

        "hours_worked": hours_worked_map[data["hours_worked"]],
        "overtime_hours": overtime_map[data["overtime_hours"]],
        "projects_handled": projects_map[data["projects_handled"]],
        "meetings_count": meetings_map[data["meetings_count"]],

        "workload_rating": data["workload_rating"],
        "deadline_pressure": data["deadline_pressure"],

        "productivity_rating": data["productivity_rating"],
        "task_delay": task_delay_map[data["task_delay"]],

        "breaks_per_day": breaks_map[data["breaks"]],
        "break_duration": break_duration_map[data["break_duration"]],

        "sick_days": sick_days_map[data["sick_days"]],
        "leave_days": leave_days_map[data["leave_days"]],
        "exhaustion_rating": data["exhaustion_rating"],

        "travel": travel_map[data["travel"]],
        "travel_enjoyment": data["travel_enjoyment"],

        "family_hours": family_time_map[data["family_time"]],
        "social_satisfaction": data["social_satisfaction"]
    }

    return encoded
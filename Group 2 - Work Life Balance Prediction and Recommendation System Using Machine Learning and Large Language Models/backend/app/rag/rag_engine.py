"""
Optimized RAG Engine
Personalized FAISS Retrieval for Work-Life Balance
"""

import os
import json
import faiss
import numpy as np
from sentence_transformers import SentenceTransformer

print("=== RAG ENGINE INITIALIZING ===")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

KB_PATH = os.path.join(BASE_DIR, "knowledge_base", "stress_tips.json")
VECTOR_DIR = os.path.join(BASE_DIR, "vector_store")
INDEX_PATH = os.path.join(VECTOR_DIR, "faiss.index")
METADATA_PATH = os.path.join(VECTOR_DIR, "metadata.npy")

EMBEDDING_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"

os.makedirs(VECTOR_DIR, exist_ok=True)

# -------------------------
# Load embedding model once
# -------------------------

model = SentenceTransformer(EMBEDDING_MODEL_NAME)

# -------------------------
# Build or Load Vector Store
# -------------------------

def build_vector_store():

    print("Building FAISS index...")

    with open(KB_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    documents = [
        item["content"] + " Recommendation: " + item["recommendation"]
        for item in data
    ]

    embeddings = model.encode(documents)

    dimension = embeddings.shape[1]

    index = faiss.IndexFlatL2(dimension)

    index.add(np.array(embeddings))

    faiss.write_index(index, INDEX_PATH)

    np.save(METADATA_PATH, data)

    return index, data


def load_vector_store():

    print("Loading existing FAISS index...")

    index = faiss.read_index(INDEX_PATH)

    metadata = np.load(METADATA_PATH, allow_pickle=True)

    return index, metadata


# -------------------------
# Initialize Index
# -------------------------

if os.path.exists(INDEX_PATH) and os.path.exists(METADATA_PATH):

    index, metadata = load_vector_store()

else:

    index, metadata = build_vector_store()

print("=== RAG ENGINE READY ===")


# -------------------------
# Personalized Retrieval
# -------------------------

def generate_recommendation(user_data, wlb_label, wlb_score, top_k=4):

    """
    Personalized semantic retrieval based on
    work-life balance conditions.
    """

    query = f"""
    Work Life Balance Label: {wlb_label}
    Work Life Balance Score: {wlb_score}

    Weekly Workload:
    Hours Worked: {user_data.get('hours_worked')}
    Overtime Hours: {user_data.get('overtime_hours')}
    Projects Handled: {user_data.get('projects_handled')}
    Meetings Attended: {user_data.get('meetings_count')}

    Work Pressure:
    Workload Rating: {user_data.get('workload_rating')}
    Deadline Pressure: {user_data.get('deadline_pressure')}
    Exhaustion Level: {user_data.get('exhaustion_rating')}

    Productivity:
    Productivity Rating: {user_data.get('productivity_rating')}
    Task Delay Frequency: {user_data.get('task_delay')}

    Recovery:
    Breaks Per Day: {user_data.get('breaks')}
    Break Duration: {user_data.get('break_duration')}

    Health:
    Sick Days: {user_data.get('sick_days')}
    Leave Days: {user_data.get('leave_days')}

    Personal Life:
    Family Time: {user_data.get('family_time')}
    Social Satisfaction: {user_data.get('social_satisfaction')}

    Work Context:
    Work Mode: {user_data.get('work_mode')}
    Commute Time: {user_data.get('commute_time')}
    """

    query_embedding = model.encode([query])

    distances, indices = index.search(query_embedding, top_k)

    retrieved_chunks = []

    for i in indices[0]:

        chunk = metadata[i]

        retrieved_chunks.append(chunk["content"])

    return "\n\n".join(retrieved_chunks)
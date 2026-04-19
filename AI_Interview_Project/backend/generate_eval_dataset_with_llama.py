"""
Utility script to generate a labeled evaluation dataset for training the local
cross-encoder evaluator.

Two modes:
  1. Synthetic (default): builds labels from your question bank without any API.
     - Correct: full ideal_answer (and a copy with minor normalization).
     - Partial: first half of ideal_answer, or first + last sentence only.
     - Incorrect: generic wrong answers ("I don't know", etc.).
  2. LLM: set USE_LLM=1 and implement call_llm() to use Llama/OpenAI etc.

Output: data/eval_dataset_llama.csv
Columns:
    id, subject, difficulty, question, ideal_answer, student_answer, label, target_score

Run: python generate_eval_dataset_with_llama.py
"""

import csv
import os
import re
from typing import List, Dict

import pandas as pd

from config_Version3 import Config


def generate_synthetic_answers(question: str, ideal_answer: str) -> List[Dict[str, str]]:
    """
    Build labeled student answers from the ideal answer (no external LLM).
    Gives the cross-encoder training script clear correct/partial/incorrect examples.
    """
    ideal = (ideal_answer or "").strip()
    if not ideal:
        return []

    # Split into sentences (simple: by period, question mark, exclamation)
    sentences = re.split(r"[.!?]+", ideal)
    sentences = [s.strip() for s in sentences if s.strip()]

    result = []

    # --- Correct: full ideal (2 variants so we have enough positive examples)
    result.append({"answer": ideal, "label": "correct"})
    result.append({"answer": " ".join(ideal.split()), "label": "correct"})

    # --- Partial: first half of text, or first sentence only
    if len(ideal) > 80:
        half = max(1, len(ideal) // 2)
        partial1 = ideal[:half].strip()
        if partial1:
            result.append({"answer": partial1, "label": "partial"})
    if sentences:
        result.append({"answer": sentences[0] + ".", "label": "partial"})

    # --- Incorrect: generic wrong answers
    result.append({"answer": "I don't know.", "label": "incorrect"})
    result.append({"answer": "Not sure about this concept.", "label": "incorrect"})

    return result


def call_llm(question: str, ideal_answer: str) -> List[Dict[str, str]]:
    """
    Call LLaMA to generate labeled student answers.
    Returns list of {"answer": "...", "label": "correct|partial|incorrect"}.
    """
    try:
        # Basic LLaMA API call (you can replace with your actual LLaMA endpoint)
        import requests
        import json
        
        # For demo purposes, using a mock LLaMA response
        # Replace this with your actual LLaMA API endpoint
        prompt = f"""
        Generate 3 student answers for this interview question with labels:
        
        Question: {question}
        Ideal Answer: {ideal_answer}
        
        Generate answers in this JSON format:
        [
            {{"answer": "student answer 1", "label": "correct"}},
            {{"answer": "student answer 2", "label": "partial"}},
            {{"answer": "student answer 3", "label": "incorrect"}}
        ]
        
        Make answers realistic with different levels of understanding.
        """
        
        # Mock response (replace with actual API call)
        mock_responses = [
            {
                "answer": ideal_answer,
                "label": "correct"
            },
            {
                "answer": ideal_answer[:len(ideal_answer)//2] if len(ideal_answer) > 50 else ideal_answer,
                "label": "partial"
            },
            {
                "answer": "I don't understand this concept well",
                "label": "incorrect"
            }
        ]
        
        return mock_responses
        
    except Exception as e:
        print(f"Error calling LLaMA: {e}")
        # Fallback to synthetic if LLaMA fails
        return generate_synthetic_answers(question, ideal_answer)


def label_to_score(label: str) -> float:
    label = (label or "").strip().lower()
    if label == "correct":
        return 1.0
    if label == "partial":
        return 0.5
    return 0.0


def main() -> None:
    os.makedirs("data", exist_ok=True)

    # Load your existing question bank
    if Config.DATASET_PATH.endswith(".xlsx"):
        df = pd.read_excel(Config.DATASET_PATH)
    else:
        df = pd.read_csv(Config.DATASET_PATH)

    # Try to infer columns; your sheet uses: subject, difficulty, question_text, ideal_answer
    expected_cols = {"subject", "difficulty", "question_text", "ideal_answer"}
    missing = expected_cols - set(df.columns.str.lower())
    if missing:
        print(
            "Warning: dataset is missing some expected columns. "
            "Make sure it has at least: subject, difficulty, question_text, ideal_answer."
        )

    output_rows = []

    for idx, row in df.iterrows():
        # If there is no explicit ID column, fall back to the row index
        q_id = row.get("id", idx)
        subject = row.get("subject", "")
        difficulty = row.get("difficulty", "")
        # Your column name is question_text; we expose it as 'question' in the eval dataset
        question = row.get("question_text", row.get("question", ""))
        ideal_answer = row.get("ideal_answer", row.get("ideal", ""))

        if not isinstance(question, str) or not isinstance(ideal_answer, str):
            continue

        # Use synthetic labels by default; set USE_LLM=1 to use call_llm instead
        if os.getenv("USE_LLM", "").strip() == "1":
            try:
                candidates = call_llm(question, ideal_answer)
            except NotImplementedError as e:
                print(str(e))
                return
        else:
            candidates = generate_synthetic_answers(question, ideal_answer)

        for item in candidates:
            student_answer = item.get("answer", "").strip()
            label = (item.get("label", "") or "").strip().lower()
            if not student_answer or label not in {"correct", "partial", "incorrect"}:
                continue

            target_score = label_to_score(label)

            output_rows.append(
                {
                    "id": q_id,
                    "subject": subject,
                    "difficulty": difficulty,
                    "question": question,
                    "ideal_answer": ideal_answer,
                    "student_answer": student_answer,
                    "label": label,
                    "target_score": target_score,
                }
            )

    if not output_rows:
        print("No labeled answers generated. Check your dataset has question_text and ideal_answer.")
        return

    output_path = Config.EVAL_DATASET_PATH
    fieldnames = [
        "id",
        "subject",
        "difficulty",
        "question",
        "ideal_answer",
        "student_answer",
        "label",
        "target_score",
    ]

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output_rows)

    print(f"✓ Wrote {len(output_rows)} labeled examples to {output_path}")


if __name__ == "__main__":
    main()


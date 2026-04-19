# Group 16 - AI Based Adaptive Interview Question Generator

## 📌 Project Description

The **AI-Based Adaptive Interview Question Generator** is an intelligent system designed to help students prepare for technical interviews in a structured and interactive way.

The system generates subject-based interview questions and evaluates user responses using Natural Language Processing (NLP) techniques. It also adapts the difficulty level of questions based on user performance, providing a personalized learning experience.

---

## 🎯 Problem Statement

Existing interview preparation platforms provide static and non-personalized question sets. They do not evaluate user performance effectively or adapt to individual learning needs.

This project addresses these limitations by developing an AI-based system that:

* Generates dynamic interview questions
* Evaluates answers automatically
* Adapts question difficulty based on performance

---

## 🚀 Features

* Automatic interview question generation
* Supports multiple subjects (DBMS, OS, DSA, etc.)
* Answer evaluation using semantic similarity
* Feedback and scoring system
* Adaptive difficulty adjustment
* Interactive web-based interface

---

## 🛠️ Tech Stack

* **Frontend:** React, HTML, CSS, JavaScript
* **Backend:** Python, FastAPI
* **Machine Learning:**
  * Sentence Transformers
  * Cross-Encoder Models
* **Libraries:** Pandas, PyTorch

---

## ⚙️ How the System Works

1. User selects subject and difficulty level
2. System generates a relevant interview question
3. User submits an answer
4. Answer is converted into embeddings
5. Semantic similarity is computed with model answer
6. System classifies response:
   * Correct
   * Partially Correct
   * Incorrect
7. Feedback is provided
8. Difficulty level is adjusted dynamically

---

## 📂 Project Structure

```
AI_Interview_Project/
│
├── backend/
│   ├── data/                                 # Dataset for interview questions
│   ├── frontend/                             # Frontend files
│   ├── routes/                               # API route handlers
│   ├── utils/                                # Utility functions
│   ├── app_Version3.py                       # Main backend application
│   ├── config_Version3.py                    # Configuration settings
│   ├── generate_eval_dataset_with_llama.py   # Dataset generation script
│   ├── train_new_dataset_models.py           # Model training script
│   └── requirements_Version3.txt             # Dependencies
```

---

## 🤖 Models

* Uses semantic similarity techniques for evaluation
* Sentence Transformers for embeddings
* Cross-Encoder for accurate similarity scoring

---

## 👥 Team Members

* Melisa Ann Santhosh
* Minna Boby
* Nivedita S Menon
* Rose Liz Martin

---

## 📌 Future Scope

* Expand dataset with more subjects
* Improve model accuracy
* Support voice-based interview practice
* Add performance tracking and analytics
* Deploy as a full web application

---

## 📖 Conclusion

This project demonstrates how AI and NLP can be used to automate interview preparation. The system provides structured practice, adaptive learning, and automated feedback, helping students improve their technical interview skills effectively.

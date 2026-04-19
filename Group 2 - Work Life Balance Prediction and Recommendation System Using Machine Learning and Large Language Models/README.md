WorkLife Balance AI – Backend

An AI-powered backend system that analyzes employee stress levels using Machine Learning, generates personalized recommendations using LLM + RAG, and tracks stress trends over time.

Features:
User Authentication (JWT-based)
ML-based Stress Prediction
LLM-powered Personalized Recommendations
RAG (Retrieval-Augmented Generation)
Weekly Stress Logging
Stress Trend Analysis
Account Deletion
MongoDB Database Integration

Tech Stack:
Backend Framework: FastAPI
Database: MongoDB
Machine Learning: scikit-learn
Embeddings: sentence-transformers
Vector Search: FAISS
LLM Engine: Ollama
Authentication: JWT (python-jose)

Setup Instructions

1. Clone the Repository
git clone <your-repo-url>
cd WorkLifeBalance

2. Create Virtual Environment
Windows:
python -m venv venv
venv\Scripts\activate

Mac/Linux:
python3 -m venv venv
source venv/bin/activate

3. Install Dependencies

pip install -r requirements.txt

4. Install MongoDB

Make sure MongoDB is installed and running locally.

Default connection used in the project:
mongodb://localhost:27017

You can verify MongoDB is running using MongoDB Compass or terminal.

5. Install Ollama (Required for LLM)

Download and install Ollama from:
https://ollama.com

Then pull the required model:
ollama pull phi3:mini

Make sure Ollama is running before starting the backend.

6. Run the Server

python -m uvicorn app.main:app --reload

Open in browser:
http://127.0.0.1:8000/docs

Swagger UI will load for API testing.

Authentication Flow
Signup using /signup
Login using /login
Copy access_token
Click Authorize in Swagger
    Enter:
    Bearer <your_token_here>

Protected routes:
/weekly-update
/stress-trend
/delete-account

Database Collections
The system uses the following MongoDB collections:
users
weekly_logs
daily_logs (if implemented)

MongoDB automatically creates collections when first data is inserted.

API Overview

Authentication:
POST /signup
POST /login
DELETE /delete-account

Stress Analysis:
POST /weekly-update
GET /stress-trend

Architecture Overview

app/

main.py
models/
schemas.py
services/
stress_service.py
llm_service.py
database/
mongo.py

stress_service.py → ML prediction logic
llm_service.py → LLM + RAG logic
mongo.py → Database connection
main.py → API endpoints

Important Notes
Passwords are currently stored as plain text (for demo purposes).
For production use, implement password hashing (bcrypt).
Ensure MongoDB and Ollama are running before starting the server.

Future Improvements
Daily stress tracking
Burnout prediction
Improved password security
Frontend integration (React/Flutter/etc.)
Deployment (Docker / Cloud hosting)


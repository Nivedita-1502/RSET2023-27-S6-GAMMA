# Living Library 📚

Living Library is an advanced AI-powered knowledge management system that transforms unstructured data (PDFs, text) into a structured knowledge graph representation. It leverages a triple-based storage system (Subject-Relation-Object) to optimize memory footprint and enable precise information retrieval with auditing capabilities.

## 🏗️ Architecture

- **Frontend**: React + TypeScript + Vite + Tailwind CSS + shadcn/ui.
- **Backend**: FastAPI (Python) + ChromaDB (Vector Store) + Neo4j (Graph Database).
- **Core Pipeline**:
  - **Ingestion**: Extracting text from files (PDF/Text).
  - **Triple Extraction**: Converting text into (Subject, Relation, Object) facts.
  - **Storage**: Storing facts in ChromaDB for semantic search and Neo4j for relationship mapping.
  - **Memory Analytics**: Computing compression ratios and memory optimization stats.
  - **Querying**: Reconstructing answers from facts with an integrated "Audit Lab" for truth and drift analysis.

## 🚀 Getting Started

### Prerequisites

- **Python 3.10+**
- **Node.js 18+**
- **Neo4j Desktop/Server** (Run on `bolt://localhost:7687` with default password `password` or update `server.py`)

### Backend Setup

1. Navigate to the backend directory:
   ```sh
   cd backend
   ```
2. (Optional) Create a virtual environment:
   ```sh
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```sh
   pip install fastapi uvicorn chromadb neo4j pypdf numpy python-multipart
   ```
4. Start the server:
   ```sh
   python server.py
   ```
   The backend will run on `http://localhost:8000`.

### Frontend Setup

1. Navigate to the frontend directory:
   ```sh
   cd frontend
   ```
2. Install dependencies:
   ```sh
   npm install
   ```
3. Start the development server:
   ```sh
   npm run dev
   ```
   The frontend will run on `http://localhost:8080` (or `5173`).

## 🛠️ Key Features

- **Document Ingestion**: Upload PDFs or text files to build your living library.
- **Audit Lab**: Analyze generated answers for "Truth Score" and "Semantic Drift" based on stored facts.
- **Memory Dashboard**: Visualize how the triple-based representation reduces the data footprint.
- **Knowledge Graph**: Explore the relationships between entities extracted from your documents.

## 📂 Project Structure

```
.
├── backend/
│   ├── core/           # Triple extraction and ingestion logic
│   ├── storage/        # ChromaDB and Neo4j interface
│   ├── semantics/      # Auditing and embeddings logic
│   ├── analytics/      # Memory usage metrics
│   └── server.py       # FastAPI application
├── frontend/
│   ├── src/
│   │   ├── components/ # UI components
│   │   ├── pages/      # Application views (Audit Lab, Dashboard, etc.)
│   │   └── lib/        # API clients and utilities
│   └── README.md
└── .gitignore
```


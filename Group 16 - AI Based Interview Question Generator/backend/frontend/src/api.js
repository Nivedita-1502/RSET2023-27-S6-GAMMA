const API_BASE_URL = '';

async function handleResponse(response) {
  if (!response.ok) {
    const errorBody = await response.json().catch(() => ({}));
    const message = errorBody.message || response.statusText || 'Request failed';
    throw new Error(message);
  }
  return response.json();
}

export async function fetchQuizInfo() {
  const res = await fetch(`${API_BASE_URL}/api/questions/info`);
  return handleResponse(res);
}

export async function fetchSubjects() {
  const res = await fetch(`${API_BASE_URL}/api/questions/subjects`);
  return handleResponse(res);
}

export async function fetchDifficulties(subject) {
  const res = await fetch(`${API_BASE_URL}/api/questions/difficulties/${encodeURIComponent(subject)}`);
  return handleResponse(res);
}

export async function fetchQuestion(subject, difficulty) {
  const res = await fetch(`${API_BASE_URL}/api/questions/get-question`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ subject, difficulty })
  });
  return handleResponse(res);
}

export async function submitAnswer(user_answer, ideal_answer, keywords, subject) {
  const res = await fetch(`${API_BASE_URL}/api/evaluation/submit-answer`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ user_answer, ideal_answer, keywords, subject })
  });
  return handleResponse(res);
}

export async function getNextDifficulty(current_difficulty, classification, subject) {
  const res = await fetch(`${API_BASE_URL}/api/evaluation/get-next-difficulty`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ current_difficulty, classification, subject })
  });
  return handleResponse(res);
}

export async function calculateStats(results) {
  const res = await fetch(`${API_BASE_URL}/api/evaluation/calculate-stats`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ results })
  });
  return handleResponse(res);
}

export async function getQuizSettings() {
  const res = await fetch(`${API_BASE_URL}/api/questions/quiz-settings`, {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' }
  });
  return handleResponse(res);
}


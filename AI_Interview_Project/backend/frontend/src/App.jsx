import React, { useEffect, useMemo, useState } from 'react';
import {
  fetchQuizInfo,
  fetchSubjects,
  fetchDifficulties,
  fetchQuestion,
  submitAnswer,
  getNextDifficulty,
  calculateStats,
  getQuizSettings
} from './api';

function App() {
  const [subjects, setSubjects] = useState([]);
  const [difficulties, setDifficulties] = useState([]);
  const [quizConfig, setQuizConfig] = useState(null);

  const [selectedSubject, setSelectedSubject] = useState('');
  const [selectedDifficulty, setSelectedDifficulty] = useState('');
  const [userName, setUserName] = useState('');  // Add user name state

  const [isLoadingMeta, setIsLoadingMeta] = useState(true);
  const [metaError, setMetaError] = useState('');

  const [currentQuestion, setCurrentQuestion] = useState(null);
  const [idealAnswer, setIdealAnswer] = useState('');
  const [userAnswer, setUserAnswer] = useState('');

  const [questionIndex, setQuestionIndex] = useState(0);
  const [currentDifficulty, setCurrentDifficulty] = useState('');
  const [lastNextDifficulty, setLastNextDifficulty] = useState(''); // Track next difficulty for final summary
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [evaluations, setEvaluations] = useState([]);
  const [finalStats, setFinalStats] = useState(null);
  const [flowError, setFlowError] = useState('');

  const totalQuestions = quizConfig?.settings?.total_questions_per_quiz ?? 3;

  const isQuizStarted = !!currentQuestion || evaluations.length > 0;
  const isQuizCompleted = !!finalStats;

  useEffect(() => {
    let isCancelled = false;
    async function loadMeta() {
      try {
        setIsLoadingMeta(true);
        setMetaError('');

        const [quizInfo, subjectsRes] = await Promise.all([
          getQuizSettings().catch((err) => {
            console.error('Failed to fetch quiz settings', err);
            return null;
          }),
          fetchSubjects()
        ]);

        if (isCancelled) return;

        if (quizInfo) {
          setQuizConfig(quizInfo);
        }

        if (subjectsRes?.success) {
          const list = subjectsRes.subjects || [];
          setSubjects(list);
          if (list.length > 0) {
            setSelectedSubject(list[0]);
          }
        } else {
          throw new Error(subjectsRes?.message || 'Unable to load subjects');
        }
      } catch (err) {
        console.error(err);
        setMetaError(err.message || 'Unable to load quiz information.');
      } finally {
        if (!isCancelled) {
          setIsLoadingMeta(false);
        }
      }
    }

    loadMeta();
    return () => {
      isCancelled = true;
    };
  }, []);

  useEffect(() => {
    let isCancelled = false;
    async function loadDifficultiesForSubject(subject) {
      if (!subject) {
        setDifficulties([]);
        setSelectedDifficulty('');
        return;
      }
      try {
        const res = await fetchDifficulties(subject);
        if (isCancelled) return;
        if (res.success) {
          const list = res.difficulties || [];
          setDifficulties(list);
          if (list.length > 0) {
            setSelectedDifficulty(list[0]);
          }
        } else {
          setDifficulties([]);
          setSelectedDifficulty('');
        }
      } catch (err) {
        console.error(err);
        if (!isCancelled) {
          setDifficulties([]);
          setSelectedDifficulty('');
        }
      }
    }

    if (selectedSubject) {
      loadDifficultiesForSubject(selectedSubject);
    }

    return () => {
      isCancelled = true;
    };
  }, [selectedSubject]);

  const progressLabel = useMemo(() => {
    const current = Math.min(questionIndex + (isQuizCompleted ? 0 : currentQuestion ? 1 : 0), totalQuestions);
    return `${current}/${totalQuestions} questions`;
  }, [questionIndex, currentQuestion, totalQuestions, isQuizCompleted]);

  async function startQuiz() {
    if (!selectedSubject || !selectedDifficulty || !userName.trim()) {
      alert('Please enter your name and select a subject and difficulty to start the quiz.');
      return;
    }
    try {
      setIsSubmitting(true);
      setFlowError('');
      setEvaluations([]);
      setFinalStats(null);
      setQuestionIndex(0);

      const res = await fetchQuestion(selectedSubject, selectedDifficulty);
      if (!res.success) {
        throw new Error(res.message || 'Unable to start quiz');
      }

      setCurrentQuestion(res.data);
      setIdealAnswer(res.ideal_answer);
      setUserAnswer('');
      setCurrentDifficulty(res.data.difficulty || selectedDifficulty);
    } catch (err) {
      console.error(err);
      setFlowError(err.message || 'Failed to start quiz.');
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleSubmitAnswer() {
    if (!userAnswer.trim() || !idealAnswer) return;
    try {
      setIsSubmitting(true);
      setFlowError('');

      const evalRes = await submitAnswer(userAnswer, idealAnswer, currentQuestion?.keywords || '', currentQuestion?.subject || '');
      if (!evalRes.success) {
        throw new Error(evalRes.message || 'Evaluation failed');
      }

      const evaluation = evalRes.evaluation;
      const similarityScore = evaluation.similarity_score ?? 0;

      const enriched = {
        ...evaluation,
        question: currentQuestion?.question,
        subject: currentQuestion?.subject,
        difficulty: currentQuestion?.difficulty
      };

      const updatedEvaluations = [...evaluations, enriched];
      setEvaluations(updatedEvaluations);

      const isLastQuestion = updatedEvaluations.length >= totalQuestions;

      if (isLastQuestion) {
        // Calculate and store the next difficulty for the last answered question
        const diffRes = await getNextDifficulty(currentDifficulty || 'easy', evaluation.classification, currentQuestion?.subject || '');
        if (diffRes.success) {
          setLastNextDifficulty(diffRes.next_difficulty || currentDifficulty || 'easy');
        }
        
        const statsRes = await calculateStats(updatedEvaluations);
        if (!statsRes.success) {
          throw new Error(statsRes.message || 'Failed to calculate stats');
        }
        setFinalStats(statsRes.stats);
        setCurrentQuestion(null);
        setIdealAnswer('');
        setUserAnswer('');
        return;
      }

      const diffRes = await getNextDifficulty(currentDifficulty || 'easy', evaluation.classification, currentQuestion?.subject || '');
      if (!diffRes.success) {
        throw new Error(diffRes.message || 'Failed to get next difficulty');
      }
      const nextDifficulty = diffRes.next_difficulty || currentDifficulty || 'easy';
      setCurrentDifficulty(nextDifficulty);

      const qRes = await fetchQuestion(selectedSubject, nextDifficulty);
      if (!qRes.success) {
        throw new Error(qRes.message || 'Failed to load next question');
      }

      setQuestionIndex((prev) => prev + 1);
      setCurrentQuestion(qRes.data);
      setIdealAnswer(qRes.ideal_answer);
      setUserAnswer('');
    } catch (err) {
      console.error(err);
      setFlowError(err.message || 'Unable to submit answer.');
    } finally {
      setIsSubmitting(false);
    }
  }

  function handleRestart() {
    setCurrentQuestion(null);
    setIdealAnswer('');
    setUserAnswer('');
    setEvaluations([]);
    setFinalStats(null);
    setQuestionIndex(0);
    setCurrentDifficulty(selectedDifficulty || 'easy');
    setFlowError('');
  }

  const latestEvaluation = evaluations[evaluations.length - 1];

  return (
    <div className="app-shell">
      <header className="app-header">
        <div>
          <div className="app-title">
            <span>AI Interview Practice</span>
            <span className="app-title-pill">Adaptive</span>
          </div>
          <div className="app-subtitle">
            Practice DBMS, DSA, OS interview questions with real-time AI feedback.
          </div>
        </div>
        <div className="badge-quiet">
          {isQuizCompleted ? 'Session complete' : isQuizStarted ? 'Live session' : 'Ready to start'}
        </div>
      </header>

      <div className="layout">
        <section className="panel">
          <div className="panel-header">
            <div>
              <div className="panel-title">Configuration & current question</div>
              <div className="panel-caption">
                Choose a subject and difficulty, then answer questions in your own words.
              </div>
            </div>
            <div className="chips-row">
              <span className="chip chip-soft">Progress · {progressLabel}</span>
            </div>
          </div>

          <div className="field-grid">
            <div className="field">
              <label>Your Name *</label>
              <input
                type="text"
                className="input"
                placeholder="Enter your name (required)"
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
                disabled={isQuizStarted}
                required
              />
            </div>
            <div className="field">
              <label>Number of Questions</label>
              <select
                className="select"
                value={totalQuestions}
                onChange={(e) => setQuizConfig(prev => ({
                  ...prev,
                  settings: {
                    ...prev?.settings,
                    total_questions_per_quiz: parseInt(e.target.value)
                  }
                }))}
                disabled={isQuizStarted}
              >
                <option value={3}>3 Questions</option>
                <option value={5}>5 Questions</option>
                <option value={10}>10 Questions</option>
                <option value={15}>15 Questions</option>
                <option value={20}>20 Questions</option>
              </select>
            </div>
            <div className="field">
              <label>Subject</label>
              <select
                className="select"
                disabled={isQuizStarted || isLoadingMeta}
                value={selectedSubject}
                onChange={(e) => setSelectedSubject(e.target.value)}
              >
                {subjects.length === 0 && <option value="">Loading…</option>}
                {subjects.map((s) => (
                  <option key={s} value={s}>
                    {s.toUpperCase()}
                  </option>
                ))}
              </select>
            </div>
            <div className="field">
              <label>Starting difficulty</label>
              <select
                className="select"
                disabled={isQuizStarted || isLoadingMeta || difficulties.length === 0}
                value={selectedDifficulty}
                onChange={(e) => setSelectedDifficulty(e.target.value)}
              >
                {difficulties.length === 0 && <option value="">Loading…</option>}
                {difficulties.map((d) => (
                  <option key={d} value={d}>
                    {d.charAt(0).toUpperCase() + d.slice(1)}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="pill-row">
            <span className="pill pill-strong">
              {quizConfig?.settings?.total_questions_per_quiz ?? 3}-question adaptive session
            </span>
          </div>

          {!isQuizStarted && (
            <div className="actions-row">
              <button
                className="primary-button"
                onClick={startQuiz}
                disabled={
                  !selectedSubject || !selectedDifficulty || !userName.trim() || isLoadingMeta || isSubmitting || !!metaError
                }
              >
                <span>{isSubmitting ? 'Preparing' : 'Start session'}</span>
                {isSubmitting && <span className="loading-dots" />}
              </button>
              <div className="hint-text">
                The system will adapt difficulty based on your answer quality.
              </div>
            </div>
          )}

          {isQuizStarted && currentQuestion && (
            <>
              <div className="question-card">
                <div className="question-label">
                  Question {questionIndex + 1} · {currentQuestion.subject?.toUpperCase()} ·{' '}
                  {currentQuestion.difficulty}
                </div>
                <div className="question-text">{currentQuestion.question}</div>
                {currentQuestion.keywords && (
                  <div className="keywords">Focus on: {currentQuestion.keywords}</div>
                )}
              </div>

              <label className="question-label" style={{ marginTop: '0.6rem' }}>
                Your answer
              </label>
              <textarea
                className="textarea"
                placeholder="Explain your answer as you would in a real interview…"
                value={userAnswer}
                onChange={(e) => setUserAnswer(e.target.value)}
              />

              <div className="actions-row">
                <button
                  className="ghost-button"
                  type="button"
                  onClick={handleRestart}
                  disabled={isSubmitting}
                >
                  Reset session
                </button>
                <button
                  className="primary-button"
                  type="button"
                  onClick={handleSubmitAnswer}
                  disabled={isSubmitting || !userAnswer.trim()}
                >
                  <span>
                    {questionIndex + 1 >= totalQuestions ? 'Submit & finish' : 'Submit answer'}
                  </span>
                  {isSubmitting && <span className="loading-dots" />}
                </button>
              </div>
            </>
          )}

          {isQuizCompleted && (
            <div className="actions-row" style={{ marginTop: '0.9rem' }}>
              <button className="primary-button" type="button" onClick={handleRestart}>
                Start new session
              </button>
              <div className="hint-text">
                Try another subject or difficulty to widen your coverage.
              </div>
            </div>
          )}

          {(metaError || flowError) && (
            <div className="error-banner">
              <strong>Error:</strong> {flowError || metaError}
            </div>
          )}
        </section>

        <aside className="panel">
          <div className="panel-header">
            <div>
              <div className="panel-title">Live feedback & summary</div>
              <div className="panel-caption">
                Track your progress and final performance.
              </div>
            </div>
          </div>

          <div className="status-row">
            <span className="status-pill">
              Evaluations · {evaluations.length}/{totalQuestions}
            </span>
            {latestEvaluation && (
              <span
                className={
                  latestEvaluation.classification === 'correct'
                    ? 'status-pill status-pill-good'
                    : latestEvaluation.classification === 'incorrect'
                    ? 'status-pill status-pill-bad'
                    : 'status-pill'
                }
              >
                Last · {latestEvaluation.classification}
              </span>
            )}
          </div>

          <div className="timeline">
            {evaluations.length === 0 && (
              <div className="timeline-item">
                <div className="timeline-question">
                  No answers evaluated yet. Once you submit, your feedback timeline will appear here.
                </div>
              </div>
            )}

            {evaluations.map((ev, idx) => (
              <div key={idx} className="timeline-item">
                <div className="timeline-content">
                  <div className="timeline-question">{ev.question}</div>
                  <div className="timeline-result-inline">
                    <span>Classification: </span>
                    <span className={`timeline-result ${ev.classification}`}>
                      {ev.classification.toUpperCase()}
                    </span>
                  </div>
                  {ev.feedback && <div className="timeline-feedback">Feedback: {ev.feedback}</div>}
                </div>
              </div>
            ))}
          </div>

          {finalStats && (
            <div className="summary-grid">
              <div className="summary-card">
                <div className="summary-label">Student</div>
                <div className="summary-value">{userName || 'Anonymous'}</div>
              </div>
              <div className="summary-card">
                <div className="summary-label">Overall accuracy</div>
                <div className="summary-value">{finalStats.accuracy_percentage}%</div>
                <div
                  className={finalStats.passed ? 'summary-badge-pass' : 'summary-badge-fail'}
                >
                  <span className="badge-dot" />
                  <span>{finalStats.passed ? 'Passing score' : 'Below passing threshold'}</span>
                </div>
              </div>
              <div className="summary-card">
                <div className="summary-label">Next difficulty</div>
                <div className="summary-value capitalize">{lastNextDifficulty || 'N/A'}</div>
                <div className="summary-badge-info">
                  <span className="badge-dot" />
                  <span>Based on last answer</span>
                </div>
              </div>
            </div>
          )}
        </aside>
      </div>
    </div>
  );
}

export default App;


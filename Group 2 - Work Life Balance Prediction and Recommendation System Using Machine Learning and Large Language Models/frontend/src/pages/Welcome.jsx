import { Link } from "react-router-dom";
import bg from "../assets/bg_wlb.png";   // place your image here

export default function Welcome() {
  return (
    <div
      className="welcome-container"
      style={{
        backgroundImage: `url(${bg})`
      }}
    >
      <div className="overlay"></div>

      <div className="welcome-card">

        <h1 className="welcome-title">
          LifeBalance AI
        </h1>

        <p className="welcome-subtitle">
          Intelligent Work‑Life Balance Assistant
        </p>

        <p className="welcome-text">
          LifeBalance AI is a smart wellness platform designed to help
          professionals understand and improve their work‑life balance.
          Using machine learning, behavioral analysis, and AI‑generated
          recommendations, the system evaluates your weekly work patterns
          and lifestyle habits to provide meaningful insights.
        </p>

        <div className="feature-list">
          <p>📊 Predict your Work‑Life Balance Score</p>
          <p>🤖 AI‑powered personalized recommendations</p>
          <p>📈 Weekly trend tracking and analytics</p>
          <p>💬 Interactive AI wellness assistant</p>
        </div>

        <div className="welcome-buttons">

          <Link to="/login">
            <button className="primary-btn">
              Login
            </button>
          </Link>

          <Link to="/signup">
            <button className="secondary-btn">
              Create Account
            </button>
          </Link>

        </div>

      </div>

    </div>
  );
}
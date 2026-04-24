import { useEffect, useState } from "react";
import { getDashboard } from "../services/api";
import FloatingChatbot from "../components/FloatingChatbot";

import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid
} from "recharts";

function Dashboard(){

  const [trend,setTrend] = useState(null);
  const [result,setResult] = useState(null);
  const [loading,setLoading] = useState(true);

  useEffect(()=>{

    const saved = localStorage.getItem("latest_result");

    if(saved){
      setResult(JSON.parse(saved));
    }

    async function loadTrend(){

      try{
        const res = await getDashboard();
        setTrend(res.data);

        if(res.data?.recommendations){
          setResult(res.data);
          localStorage.setItem("latest_result", JSON.stringify(res.data));
        }

      }
      catch(err){
        console.log("Trend API failed:",err);
      }

      setLoading(false);
    }

    loadTrend();

  },[]);

  if(loading){
    return <p style={{padding:"30px"}}>Loading dashboard...</p>;
  }

  return(

    <div className="dashboard-container">

      <h1 className="dashboard-title">WorkLife Balance Dashboard</h1>

      {/* ---------------- ML RESULT ---------------- */}

      {result ? (

        <div className="score-card">

          <h3>Your Work-Life Balance Score</h3>

          <div className="score-number">
            {result.wlb_score}
          </div>

          <p className="status">
            Status: <strong>{result.wlb_label}</strong>
          </p>

        </div>

      ) : (

        <p>No weekly check-in data yet.</p>

      )}

      {/* ---------------- AI RECOMMENDATIONS ---------------- */}

      {result?.recommendations?.length > 0 && (

        <div className="recommendation-box">

          <h3>AI Recommendations</h3>

          <ul>
            {result.recommendations.map((r,i)=>(
              <li key={i}>{r}</li>
            ))}
          </ul>

        </div>

      )}

      {/* ---------------- WEEKLY CHECKLIST ---------------- */}

      {result?.weekly_checklist?.length > 0 && (

        <div className="checklist-box">

          <h3>Suggested Weekly Checklist</h3>

          {result.weekly_checklist.map((item,i)=>(
            <div key={i} className="check-item">
              <input type="checkbox" />
              <span>{item}</span>
            </div>
          ))}

        </div>

      )}

      {/* ---------------- TREND ANALYSIS ---------------- */}

      <div className="trend-box">

        <h3>Trend Analysis</h3>

        {trend?.message ? (

          <p>{trend.message}</p>

        ) : (

          <>

            <div style={{width:"100%",height:"250px"}}>

              <ResponsiveContainer>

                <LineChart
                  data={trend?.last_5_weeks?.map((score,index)=>({
                    week:`Week ${index+1}`,
                    score:score
                  }))}
                >

                  <CartesianGrid strokeDasharray="3 3" />

                  <XAxis dataKey="week" />

                  <YAxis />

                  <Tooltip />

                  <Line
                    type="monotone"
                    dataKey="score"
                    stroke="#0A4D8C"
                    strokeWidth={3}
                  />

                </LineChart>

              </ResponsiveContainer>

            </div>

            <div style={{marginTop:"15px"}}>
              <p>Current Score: {trend?.current_wlb_score ?? "N/A"}</p>
              <p>Previous Score: {trend?.previous_wlb_score ?? "N/A"}</p>
              <p>Trend: {trend?.trend ?? "N/A"}</p>
              <p>Change: {trend?.change ?? "N/A"}</p>
            </div>

          </>

        )}

      </div>

      {/* ---------------- LAST 5 WEEKS ---------------- */}

      {trend?.last_5_weeks?.length > 0 && (

        <div className="weeks-box">

          <h3>Last 5 Weeks Scores</h3>

          <ul>
            {trend.last_5_weeks.map((score,index)=>(
              <li key={index}>{score}</li>
            ))}
          </ul>

        </div>

      )}

      {/* ---------------- FLOATING CHATBOT ---------------- */}

      <FloatingChatbot/>

    </div>

  );

}

export default Dashboard;
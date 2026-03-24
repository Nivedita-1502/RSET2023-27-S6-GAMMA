import { useState } from "react";
import { Routes, Route, useNavigate, useLocation } from "react-router-dom";
import ChatPage from "./pages/ChatPage";
import AuditLabPage from "./pages/AuditLabPage";

// 1. Define the shape of our Audit Data to keep TypeScript happy
interface AuditReport {
  truth_analysis: {
    truth_score: number;
    verified: number;
    total_claims: number;
    claims: any[];
  };
  drift_analysis: {
    drift_score: number;
  };
}

function App() {
  // 2. State for the audit data
  const [claims, setClaims] = useState<any[]>([]);

  const navigate = useNavigate();
  const location = useLocation();
  const activeTab = location.pathname === "/audit-lab" ? "audit" : "chat";

  // 3. Handler to receive data from ChatPage
  const handleNewAudit = (auditData: any) => {
    console.log("Audit data received in App:", auditData);
    const newClaims = auditData?.truth_analysis?.claims || [];
    setClaims(newClaims);
  };

  return (
    <div className="flex h-screen w-full bg-background text-foreground">
      {/* SIDEBAR NAVIGATION */}
      <nav className="w-64 border-r bg-card p-4 flex flex-col gap-2 shadow-sm">
        <div className="flex items-center gap-2 mb-8 px-2">
          <div className="h-8 w-8 rounded-lg bg-primary flex items-center justify-center text-white font-bold">
            L
          </div>
          <h1 className="text-xl font-bold tracking-tight">Living Library</h1>
        </div>

        <button 
          onClick={() => navigate("/")}
          className={`flex items-center gap-3 p-3 text-sm font-medium transition-all rounded-lg ${
            activeTab === 'chat' 
              ? 'bg-primary text-primary-foreground shadow-md' 
              : 'text-muted-foreground hover:bg-muted hover:text-foreground'
          }`}
        >
          <span className="text-lg">💬</span> Chat Assistant
        </button>

        <button 
          onClick={() => navigate("/audit-lab")}
          className={`flex items-center gap-3 p-3 text-sm font-medium transition-all rounded-lg ${
            activeTab === 'audit' 
              ? 'bg-primary text-primary-foreground shadow-md' 
              : 'text-muted-foreground hover:bg-muted hover:text-foreground'
          }`}
        >
          <span className="text-lg">🔍</span> Audit Intelligence
        </button>

        <div className="mt-auto p-4 bg-muted/50 rounded-xl">
          <p className="text-[10px] uppercase font-bold text-muted-foreground mb-1">System Status</p>
          <div className="flex items-center gap-2 text-xs text-green-600">
            <div className="h-2 w-2 rounded-full bg-green-500 animate-pulse" />
            Backend Connected
          </div>
        </div>
      </nav>

      {/* MAIN CONTENT AREA */}
      <main className="flex-1 overflow-auto bg-slate-50/30">
        <div className="h-full w-full">
          <Routes>
            <Route path="/" element={<ChatPage onAuditReceived={handleNewAudit} />} />
            <Route path="/audit-lab" element={
              <div className="p-8 max-w-6xl mx-auto">
                <AuditLabPage claims={claims} />
              </div>
            } />
          </Routes>
        </div>
      </main>
    </div>
  );
}

export default App;
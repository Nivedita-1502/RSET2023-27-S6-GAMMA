import { ArrowLeft, Shield, Loader2, Trash2 } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useState, useEffect } from "react";
import FactCheckTable, { Claim } from "@/components/FactCheckTable";
import KnowledgeFlow from "@/components/KnowledgeFlow";
import KnowledgeGraph from "@/components/KnowledgeGraph";
import SemanticDrift from "@/components/SemanticDrift";
import CompressionEfficiency from "@/components/CompressionEfficiency";
import TruthScoreStability from "@/components/TruthScoreStability";
import { getSystemStats, getAllTriples, getMemoryDashboard, resetDatabase, type TripleInfo, type SystemStats, type MemoryDashboard } from "@/lib/api";

// 1. ADD THIS INTERFACE to accept props from App.tsx
interface AuditLabPageProps {
  claims?: Claim[];
}

// 2. Update the function to accept { claims }
const AuditLabPage = ({ claims: liveClaims }: AuditLabPageProps) => {
  const navigate = useNavigate();
  const [claims, setClaims] = useState<Claim[]>([]);
  const [stats, setStats] = useState<SystemStats | null>(null);
  const [dashboard, setDashboard] = useState<MemoryDashboard | null>(null);
  const [triples, setTriples] = useState<TripleInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsData, triplesData, dashboardData] = await Promise.all([
          getSystemStats(),
          getAllTriples(),
          getMemoryDashboard(),
        ]);
        setStats(statsData);
        setTriples(triplesData.triples);
        setDashboard(dashboardData);

        // 3. LOGIC CHANGE: 
        // If we have 'liveClaims' from the chat, use those!
        // Otherwise, fall back to the historical triples from the database.
        if (liveClaims && liveClaims.length > 0) {
          setClaims(liveClaims);
        } else {
          const historicalClaims: Claim[] = triplesData.triples.slice(0, 20).map((t, i) => ({
            id: t.id || String(i),
            claim: `${t.subject} → ${t.relation} → ${t.object}`,
            sourceCapsule: "Database_Historical",
            status: "verified" as const,
          }));
          setClaims(historicalClaims);
        }
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [liveClaims]); // Re-run if liveClaims updates

  const handleDeleteDatabase = async () => {
    if (!confirm("Are you sure you want to delete all database knowledge? This cannot be undone.")) return;
    setIsDeleting(true);
    try {
      await resetDatabase();
      setClaims([]);
      setTriples([]);
      setStats(null);
      setDashboard(null);
      alert("Database successfully reset!");
      // Optionally reload the page or fetch initial states
      window.location.reload();
    } catch (err: any) {
      alert(`Failed to reset database: ${err.message}`);
    } finally {
      setIsDeleting(false);
    }
  };

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return "0 Bytes";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  };

  // ... (Keep all your existing compressionData logic and return statement exactly as they were)
  const compressionData = dashboard?.latest_run
    ? {
      originalMB: formatBytes(dashboard.latest_run.raw_text_bytes || 0),
      compressedKB: formatBytes(dashboard.latest_run.compressed_bytes || 0),
      reduction: dashboard.latest_run.percent_reduction ?? 0,
    }
    : null;

  return (
    <div className="min-h-screen bg-background text-foreground">
      {/* ... Your entire original return block with all the components ... */}
      {/* (Exactly as you had it before) */}
      <div className="sticky top-0 z-10 flex items-center justify-between border-b bg-background px-6 py-4">
        <div className="flex items-center gap-4">
          <button onClick={() => navigate("/")} className="flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors hover:bg-secondary">
            <ArrowLeft className="h-4 w-4" /> Back to Chat
          </button>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary text-primary-foreground">
              <Shield className="h-5 w-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold">Audit Lab</h1>
              <p className="text-sm text-muted-foreground">Research Dashboard</p>
            </div>
          </div>
        </div>
        <button 
          onClick={handleDeleteDatabase} 
          disabled={isDeleting || loading}
          className="flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-red-700 disabled:opacity-50"
        >
          {isDeleting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
          Delete All Database
        </button>
      </div>

      <div className="mx-auto max-w-5xl space-y-6 p-6">
        {loading ? (
          <div className="flex justify-center py-20"><Loader2 className="animate-spin" /></div>
        ) : (
          <>
            <FactCheckTable claims={claims} />
            <KnowledgeFlow
              triplesCount={stats?.vector_store?.total_triples ?? 0}
              documentsProcessed={dashboard?.total_documents_processed ?? 0}
            />
            <KnowledgeGraph triples={triples} />
            <div className="grid gap-6 md:grid-cols-2">
              <SemanticDrift />
              <CompressionEfficiency {...compressionData} />
            </div>
            <TruthScoreStability />
          </>
        )}
      </div>
    </div>
  );
};

export default AuditLabPage;
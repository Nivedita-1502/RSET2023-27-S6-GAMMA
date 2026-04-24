import { useState, useRef, useEffect } from "react";
import { Send, Paperclip } from "lucide-react";
import ChatMessage, { Message } from "@/components/ChatMessage";
import PerformanceMetrics from "@/components/PerformanceMetrics";
import { useNavigate } from "react-router-dom";
import { queryKnowledge, ingestFile, type QueryResponse } from "@/lib/api";

// 1. Define the props interface to match App.tsx
interface ChatPageProps {
  onAuditReceived: (data: any) => void;
}

const initialMessages: Message[] = [
  {
    id: "1",
    role: "bot",
    content: "Hello! I'm your AI assistant. Upload a document first, then ask me anything about it.",
    timestamp: "10:30 AM",
  },
];

// 2. Accept onAuditReceived as a prop
const ChatPage = ({ onAuditReceived }: ChatPageProps) => {
  const navigate = useNavigate();
  const [messages, setMessages] = useState<Message[]>(initialMessages);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Live metrics states
  const [truthScore, setTruthScore] = useState(0);
  const [accuracy, setAccuracy] = useState(0);
  const [compression, setCompression] = useState({
    fileName: "No file",
    originalSize: "0 MB",
    compressedSize: "0 KB",
    reduction: "0%",
  });
  const [trendData, setTrendData] = useState<{ query: number; score: number }[]>([]);
  const queryCountRef = useRef(0);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const addMessage = (role: "bot" | "user", content: string): Message => {
    const msg: Message = {
      id: Date.now().toString() + Math.random(),
      role,
      content,
      timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
    };
    setMessages((prev) => [...prev, msg]);
    return msg;
  };

  // 3. COMPLETE sendMessage function with data pushing and safety checks
  const sendMessage = async () => {
    if (!input.trim() || isLoading) return;

    const question = input;
    addMessage("user", question);
    setInput("");
    setIsLoading(true);

    try {
      const result: QueryResponse = await queryKnowledge(question);

      // Add bot response to UI
      addMessage("bot", result.answer);

      // PUSH DATA TO AUDIT LAB (Via App.tsx)
      // We check if result.audit exists to prevent crashing
      if (result.audit && onAuditReceived) {
        onAuditReceived(result.audit);
      }

      // UPDATE LOCAL SIDEBAR METRICS
      // Using optional chaining (?.) and fallbacks (||) for safety
      const score = Math.round(result.audit?.truth_analysis?.truth_score || 0);
      setTruthScore(score);

      const verified = result.audit?.truth_analysis?.verified || 0;
      const total = result.audit?.truth_analysis?.total_claims || 0;
      setAccuracy(total > 0 ? Math.round((verified / total) * 100) : 0);

      // Update Trend Graph
      queryCountRef.current += 1;
      setTrendData((prev) => {
        const next = [...prev, { query: queryCountRef.current, score }];
        return next.slice(-10);
      });

    } catch (err: any) {
      addMessage("bot", `⚠️ Backend error: ${err.message}. Make sure the FastAPI server is running on port 8000.`);
    } finally {
      setIsLoading(false);
    }
  };

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return "0 Bytes";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setIsLoading(true);
    addMessage("user", `📎 Uploading "${file.name}"...`);

    try {
      const result = await ingestFile(file);
      const stats = result.memory_stats;

      const origStr = formatBytes(stats.raw_text_bytes);
      const compStr = formatBytes(stats.compressed_bytes);

      setCompression({
        fileName: file.name,
        originalSize: origStr,
        compressedSize: compStr,
        reduction: `${stats.percent_reduction}%`,
      });

      addMessage(
        "bot",
        `✅ File "${file.name}" ingested! ${result.triples_ingested} triples extracted.\n` +
        `Original: ${origStr} → Compressed: ${compStr} (${stats.percent_reduction}% reduction)`
      );
    } catch (err: any) {
      addMessage("bot", `⚠️ Upload failed: ${err.message}.`);
    } finally {
      setIsLoading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  return (
    <div className="flex h-screen w-full bg-background">
      {/* Main Chat Window */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Header */}
        <div className="border-b bg-card/50 px-6 py-4 backdrop-blur-sm">
          <h1 className="text-xl font-bold">Verification Assistant</h1>
          <p className="text-xs text-muted-foreground">
            Semantic Audit Engine Active
          </p>
        </div>

        {/* Messages List */}
        <div className="flex-1 overflow-y-auto px-6 py-4">
          <div className="mx-auto flex max-w-3xl flex-col gap-6">
            {messages.map((msg) => (
              <ChatMessage key={msg.id} message={msg} />
            ))}
            {isLoading && (
              <div className="flex items-center gap-2 text-sm text-muted-foreground animate-pulse">
                <div className="h-2 w-2 rounded-full bg-primary" />
                Processing request...
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>
        </div>

        {/* Input Bar */}
        <div className="border-t bg-card/50 px-6 py-4">
          <div className="mx-auto flex max-w-3xl items-center gap-3">
            <input
              type="file"
              ref={fileInputRef}
              className="hidden"
              onChange={handleFileUpload}
            />
            <button
              onClick={() => fileInputRef.current?.click()}
              disabled={isLoading}
              className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border bg-background hover:bg-muted disabled:opacity-50 transition-colors"
            >
              <Paperclip className="h-5 w-5" />
            </button>
            <input
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && sendMessage()}
              placeholder="Ask a question about your data..."
              disabled={isLoading}
              className="flex-1 rounded-xl border bg-background px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-primary/20 disabled:opacity-50"
            />
            <button
              onClick={sendMessage}
              disabled={isLoading}
              className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground hover:opacity-90 disabled:opacity-50 transition-opacity"
            >
              <Send className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Performance Sidebar */}
      <PerformanceMetrics
        truthScore={truthScore}
        accuracy={accuracy}
        compression={compression}
        trendData={trendData}
        onAuditLabClick={() => navigate("/audit-lab")}
      />
    </div>
  );
};

export default ChatPage;
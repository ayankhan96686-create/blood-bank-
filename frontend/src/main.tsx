import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'

interface ErrorBoundaryProps {
  children: React.ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error("Clinical Workstation Uncaught Error:", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-slate-100 flex items-center justify-center p-6 text-slate-900 font-mono">
          <div className="bg-white border-2 border-red-700 p-6 rounded shadow-xl max-w-xl w-full space-y-4">
            <div className="flex items-center gap-2 text-red-700 font-bold text-base">
              <span>WORKSTATION DIAGNOSTIC HALT</span>
            </div>
            <p className="text-xs text-slate-600">
              A runtime component exception was intercepted. Error trace:
            </p>
            <pre className="bg-red-50 text-red-900 border border-red-200 p-3 rounded text-[11px] overflow-x-auto whitespace-pre-wrap">
              {this.state.error?.message}
              {"\n"}
              {this.state.error?.stack}
            </pre>
            <button
              onClick={() => window.location.reload()}
              className="bg-slate-900 text-white px-4 py-1.5 rounded text-xs font-bold hover:bg-slate-800 transition"
            >
              RELOAD WORKSTATION
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </React.StrictMode>,
)

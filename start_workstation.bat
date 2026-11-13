@echo off
echo ===============================================================================
echo Starting e-RaktKosh Regional Blood Transfusion Workstation (Gwalior Corridor)
echo Course: DBMS CSL0311 - PbBL ITM University Gwalior
echo ===============================================================================

echo [1/2] Starting FastAPI Backend on http://localhost:8000...
start "Blood Bank FastAPI Backend (Port 8000)" cmd /k "cd /d %~dp0backend && python main.py"

echo [2/2] Starting Vite React Frontend on http://localhost:5173...
start "Blood Bank Workstation Frontend (Port 5173)" cmd /k "cd /d %~dp0frontend && npm run dev -- --host 0.0.0.0 --port 5173"

echo.
echo Workstation is starting up!
echo - Frontend UI: http://localhost:5173
echo - Backend API: http://localhost:8000 (Swagger docs: http://localhost:8000/docs)
echo ===============================================================================

# ScamShield Backend (FastAPI)

Backend API for ScamShield, an AI and Blockchain-based platform for detecting and reporting Facebook scams, including phishing, fake accounts, and spam.

## 1. System Workflow

Screenshot Upload → Report Submission → AI Analysis → Risk and Confidence Evaluation → Verified / Suspicious Decision → Blockchain Recording (Verified Reports Only) → Supabase Database → Public Search and Verification.

## 2. Technologies Used

- Python
- FastAPI
- Supabase
- Scikit-learn (planned AI integration)
- Solidity and Ganache (planned Blockchain integration)
- SHA-256
- Flutter (Frontend)

## 3. Project Structure

```text
ScamShield/
│
├── backend/
│   ├── main.py
│   ├── database.py
│   ├── logic.py
│   ├── retry_helper.py
│   ├── test_backend.py
│   ├── README.md
│   ├── requirements.txt
│   └── .env
│
├── ai_module/
│   └── ai_engine.py
│
├── blockchain_module/
│   └── ledger.py
│
└── frontend/
    └── Flutter application
```

## 4. Environment Setup

Create and activate the virtual environment:

```powershell
cd C:\Projects\ScamShield\backend

.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
pip install -r requirements.txt
```

## 5. Environment Variables

Create a `.env` file inside the backend folder.

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Never commit `.env` to GitHub.

## 6. Run the Backend Server

```powershell
uvicorn main:app --reload
```

API documentation:

http://127.0.0.1:8000/docs

## 7. API Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/` | Backend health check |
| POST | `/api/ai/analyze` | Analyze scam information |
| POST | `/api/blockchain/record` | Record a report on the current ledger |
| GET | `/api/blockchain/verify/{tx_hash}` | Verify blockchain transaction |
| POST | `/api/upload-screenshot` | Upload screenshot to Supabase Storage |
| POST | `/api/reports/submit` | Analyze and submit scam report |
| GET | `/api/reports/search` | Search verified reports |
| GET | `/api/reports/suspicious` | View suspicious report metadata |
| GET | `/api/reports/verify/{report_id}` | Verify report integrity using SHA-256 |
| GET | `/api/stats` | Get verified report statistics |

## 8. Scam Categories

The backend supports three categories:

- phishing
- fake_account
- spam

## 9. Report Verification Logic

A report is marked as verified only when both conditions are satisfied:

- AI confidence is greater than 60%.
- Risk score is 50 or higher.

Otherwise, the report is marked as suspicious.

Only verified reports are recorded on the current blockchain ledger.

## 10. Screenshot Upload

Supported formats:

- PNG
- JPEG
- WEBP

Maximum file size: 5 MB.

Uploaded screenshots are stored in the Supabase Storage bucket:

`scam-evidence`

The returned public URL can be included in a report submission.

## 11. Database

Database platform: Supabase.

Main table: `scam_reports`

Important fields include:

- id
- category
- description
- target_url
- target_account
- message_text
- screenshot_url
- ocr_text
- risk_score
- confidence
- ai_analysis
- status
- blockchain_tx_hash
- report_hash
- created_at

A separate `suspicious_reports_public` view provides metadata-only access to suspicious reports.

## 12. Report Integrity

The backend generates a SHA-256 hash using the report description, category, target URL, target account, and message text.

The verification endpoint recalculates the hash and compares it with the stored hash.

## 13. Retry Mechanism

The `retry_helper.py` module provides retry handling for selected Supabase operations when temporary connection errors occur.

## 14. Testing

Run the backend unit tests:

```powershell
python -m unittest test_backend -v
```

**Current test coverage: 15 unit tests.**

All 15 tests passed successfully in the latest test run.

## 15. Current Development Status

### Backend

Core API endpoints, database integration, report submission, screenshot upload, report verification, and unit testing are implemented.

### AI Module

The current AI engine uses rule-based analysis with a fixed confidence value. Machine Learning models, SHAP explainability, and OCR integration remain to be completed by the AI team.

### Blockchain Module

The current implementation uses a Python-based ledger simulation. Ganache and Solidity smart contract integration remain to be completed by the Blockchain team.

### Frontend

The Flutter application will integrate with the backend APIs.

## 16. Security Notes

- Environment variables must not be committed to GitHub.
- CORS currently permits localhost origins.
- Supabase Row Level Security policies control database access.
- Verified reports are publicly searchable.
- Suspicious report listings expose metadata only.
- Authentication and administrative access requirements need further confirmation.
# ScamShield Backend (FastAPI)

Backend API for ScamShield: an AI + blockchain platform for detecting and reporting Facebook scams (phishing, fake accounts, spam).

## Flow

Screenshot upload -> Report submit -> AI analysis -> 60% confidence rule -> Blockchain record -> Supabase save -> Public search / stats / integrity verify

## Setup

1. Create and activate the virtual environment:

```powershell
cd backend
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2. Create `backend/.env` (never commit this file):

```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_publishable_key
```

3. Run the server:

```powershell
uvicorn main:app --reload
```

Interactive API docs: http://127.0.0.1:8000/docs

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/` | Health check |
| POST | `/api/upload-screenshot` | Upload PNG/JPEG/WEBP (max 5 MB), returns `screenshot_url` |
| POST | `/api/reports/submit` | Analyze + save a report. `scam_type`: `phishing`, `fake_account` or `spam` |
| GET | `/api/reports/search?url=...` or `?account=...` | Search verified reports |
| GET | `/api/reports/verify/{report_id}` | Recompute SHA-256 and check the report was not tampered with |
| GET | `/api/stats` | Verified report counts per category |
| GET | `/api/blockchain/verify/{tx_hash}` | Verify a ledger transaction hash |

## Tests

```powershell
python -m unittest test_backend -v
```

## Notes

- Reports with AI confidence above 60% are marked `verified` and recorded on the ledger; others are `suspicious`.
- The AI module currently uses a rule-based engine with a fixed confidence; it will be replaced by the ML model.
- The blockchain module is currently a Python ledger simulation; it will be replaced by the Ganache/Solidity contract.
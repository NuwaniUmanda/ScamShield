import sys
import os
from typing import Optional, List, Dict, Any

# Ensure parent directory is in path so we can import ai_module & blockchain_module
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from ai_module.ai_engine import ai_engine
from blockchain_module.ledger import blockchain_ledger

app = FastAPI(
    title="ScamShield API Server",
    description="Backend API service connecting AI Scam Intelligence & Blockchain Ledger for ScamShield",
    version="1.0.0"
)

# Enable CORS for Flutter app (Web, Android, iOS, Desktop)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic Schemas
class AIAnalysisRequest(BaseModel):
    title: str
    description: str
    scam_type: Optional[str] = "other"
    target_url: Optional[str] = None
    target_phone: Optional[str] = None
    target_wallet: Optional[str] = None
    target_email: Optional[str] = None
    financial_loss: Optional[float] = 0.0

class BlockchainRecordRequest(BaseModel):
    report_id: str
    title: str
    scam_type: str
    risk_score: int
    target_info: Optional[str] = ""

class FullReportSubmitRequest(BaseModel):
    title: str
    description: str
    scam_type: str
    target_url: Optional[str] = None
    target_phone: Optional[str] = None
    target_wallet: Optional[str] = None
    target_email: Optional[str] = None
    financial_loss: Optional[float] = 0.0
    evidence_urls: Optional[List[str]] = []

@app.get("/")
def health_check():
    return {
        "status": "online",
        "service": "ScamShield Backend API",
        "ai_engine": "active",
        "blockchain_ledger": "active",
        "contract_address": blockchain_ledger.CONTRACT_ADDRESS
    }

@app.post("/api/ai/analyze")
def analyze_scam(req: AIAnalysisRequest):
    """
    Evaluates scam report details using AI NLP intent recognition,
    domain risk checking, and threat scoring algorithms.
    """
    result = ai_engine.analyze_report(
        title=req.title,
        description=req.description,
        scam_type=req.scam_type or "other",
        target_url=req.target_url,
        target_phone=req.target_phone,
        target_wallet=req.target_wallet,
        target_email=req.target_email,
        financial_loss=req.financial_loss or 0.0
    )
    return result

@app.post("/api/blockchain/record")
def record_on_blockchain(req: BlockchainRecordRequest):
    """
    Cryptographically logs a verified report on the ScamShield blockchain ledger.
    """
    block_entry = blockchain_ledger.record_scam_on_chain(
        report_id=req.report_id,
        title=req.title,
        scam_type=req.scam_type,
        risk_score=req.risk_score,
        target_info=req.target_info or ""
    )
    return block_entry

@app.get("/api/blockchain/verify/{tx_hash}")
def verify_blockchain_hash(tx_hash: str):
    """
    Validates a transaction hash against the immutable ledger history.
    """
    verification = blockchain_ledger.verify_hash(tx_hash)
    if not verification.get("is_valid"):
        raise HTTPException(status_code=404, detail=verification.get("message", "Hash invalid"))
    return verification

@app.post("/api/reports/submit-and-analyze")
def submit_and_analyze(req: FullReportSubmitRequest):
    """
    One-stop backend endpoint that runs AI risk assessment and Pre-prepares blockchain fingerprint.
    """
    ai_result = ai_engine.analyze_report(
        title=req.title,
        description=req.description,
        scam_type=req.scam_type,
        target_url=req.target_url,
        target_phone=req.target_phone,
        target_wallet=req.target_wallet,
        target_email=req.target_email,
        financial_loss=req.financial_loss or 0.0
    )

    return {
        "status": "evaluated",
        "ai_result": ai_result,
        "payload": req.dict()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

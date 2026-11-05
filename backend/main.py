
import sys
import os
import uuid
import hashlib
import json
from typing import Optional, List, Literal

# Ensure parent directory is in path
sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
)

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from ai_module.ai_engine import ai_engine
from blockchain_module.ledger import blockchain_ledger
from database import supabase
from logic import decide_status
from retry_helper import with_retry


app = FastAPI(
    title="ScamShield API Server",
    description="Backend API service connecting AI Scam Intelligence & Blockchain Ledger for ScamShield",
    version="1.0.0"
)


# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

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
    scam_type: Literal["phishing", "fake_account", "spam"]
    target_url: Optional[str] = None
    target_account: Optional[str] = None
    message_text: Optional[str] = None
    screenshot_url: Optional[str] = None
    target_phone: Optional[str] = None
    target_wallet: Optional[str] = None
    target_email: Optional[str] = None
    financial_loss: Optional[float] = 0.0
    evidence_urls: Optional[List[str]] = []


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def compute_report_hash(
    description,
    category,
    target_url,
    target_account,
    message_text
) -> str:

    """Create a SHA-256 fingerprint of report content."""

    return hashlib.sha256(
        json.dumps(
            {
                "description": description,
                "category": category,
                "target_url": target_url,
                "target_account": target_account,
                "message_text": message_text,
            },
            sort_keys=True,
        ).encode("utf-8")
    ).hexdigest()


# ---------------------------------------------------------------------------
# Health Check
# ---------------------------------------------------------------------------

@app.get("/")
def health_check():

    return {
        "status": "online",
        "service": "ScamShield Backend API",
        "ai_engine": "active",
        "blockchain_ledger": "active",
        "contract_address": blockchain_ledger.CONTRACT_ADDRESS
    }


# ---------------------------------------------------------------------------
# AI Analysis
# ---------------------------------------------------------------------------

@app.post("/api/ai/analyze")
def analyze_scam(req: AIAnalysisRequest):

    return ai_engine.analyze_report(
        title=req.title,
        description=req.description,
        scam_type=req.scam_type or "other",
        target_url=req.target_url,
        target_phone=req.target_phone,
        target_wallet=req.target_wallet,
        target_email=req.target_email,
        financial_loss=req.financial_loss or 0.0
    )


# ---------------------------------------------------------------------------
# Blockchain
# ---------------------------------------------------------------------------

@app.post("/api/blockchain/record")
def record_on_blockchain(req: BlockchainRecordRequest):

    return blockchain_ledger.record_scam_on_chain(
        report_id=req.report_id,
        title=req.title,
        scam_type=req.scam_type,
        risk_score=req.risk_score,
        target_info=req.target_info or ""
    )


@app.get("/api/blockchain/verify/{tx_hash}")
def verify_blockchain_hash(tx_hash: str):

    verification = blockchain_ledger.verify_hash(tx_hash)

    if not verification.get("is_valid"):
        raise HTTPException(
            status_code=404,
            detail=verification.get("message", "Hash invalid")
        )

    return verification


# ---------------------------------------------------------------------------
# Submit Scam Report
# ---------------------------------------------------------------------------

@app.post("/api/reports/submit")
def submit_report(req: FullReportSubmitRequest):

    """
    Analyze report using AI.
    Decide verified or suspicious using confidence and risk score.
    Record verified reports on blockchain.
    Save reports to Supabase.
    """

    # Include Facebook-specific text in AI analysis
    ai_description = req.description

    if req.message_text:
        ai_description += " " + req.message_text

    if req.target_account:
        ai_description += " " + req.target_account

    # AI analysis
    ai_result = ai_engine.analyze_report(
        title=req.title,
        description=ai_description,
        scam_type=req.scam_type,
        target_url=req.target_url,
        target_phone=req.target_phone,
        target_wallet=req.target_wallet,
        target_email=req.target_email,
        financial_loss=req.financial_loss or 0.0
    )

    # Decide report status
    status = decide_status(
        ai_result["confidence"],
        ai_result["risk_score"]
    )

    report_id = str(uuid.uuid4())

    # Generate SHA-256 report hash
    report_hash = compute_report_hash(
        req.description,
        req.scam_type,
        req.target_url,
        req.target_account,
        req.message_text
    )

    tx_hash = None

    # Record only verified reports on blockchain
    if status == "verified":

        try:
            block = blockchain_ledger.record_scam_on_chain(
                report_id=report_id,
                title=req.title,
                scam_type=req.scam_type,
                risk_score=ai_result["risk_score"],
                target_info=req.target_url or req.target_account or ""
            )

            tx_hash = block["tx_hash"]

        except Exception as e:

            raise HTTPException(
                status_code=500,
                detail=f"Blockchain error: {e}"
            )

    # Prepare database record
    row = {
        "id": report_id,
        "category": req.scam_type,
        "description": req.description,
        "target_url": req.target_url,
        "target_account": req.target_account,
        "message_text": req.message_text,
        "screenshot_url": req.screenshot_url,
        "risk_score": ai_result["risk_score"],
        "confidence": ai_result["confidence"],
        "ai_analysis": ai_result,
        "status": status,
        "blockchain_tx_hash": tx_hash,
        "report_hash": report_hash,
    }

    # Insert without requesting the inserted database row.
    # This avoids requiring SELECT permission for suspicious reports.
    try:

        with_retry(
            lambda: supabase.table("scam_reports")
            .insert(row, returning="minimal")
            .execute()
        )

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=f"Database error: {e}"
        )

    return {
        "status": status,
        "ai_result": ai_result,
        "saved": [row]
    }


# ---------------------------------------------------------------------------
# Public Scam Search
# ---------------------------------------------------------------------------

@app.get("/api/reports/search")
def search_reports(
    url: Optional[str] = None,
    account: Optional[str] = None
):

    if not url and not account:
        raise HTTPException(
            status_code=400,
            detail="Provide url or account to search"
        )

    try:

        query = supabase.table("scam_reports").select(
            "id,category,target_url,target_account,screenshot_url,risk_score,status,blockchain_tx_hash,report_hash,created_at"
        ).eq("status", "verified")

        if url:
            query = query.ilike("target_url", f"%{url}%")

        if account:
            query = query.ilike("target_account", f"%{account}%")

        result = with_retry(lambda: query.execute())

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=f"Database error: {e}"
        )

    return {
        "found": len(result.data) > 0,
        "count": len(result.data),
        "results": result.data
    }


# ---------------------------------------------------------------------------
# Suspicious Reports (Metadata Only)
# ---------------------------------------------------------------------------

@app.get("/api/reports/suspicious")
def list_suspicious_reports(limit: int = 20):

    limit = max(1, min(limit, 100))

    try:

        result = with_retry(
            lambda: supabase.table("suspicious_reports_public")
            .select("id,category,risk_score,created_at")
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=f"Database error: {e}"
        )

    return {
        "count": len(result.data),
        "results": result.data
    }


# ---------------------------------------------------------------------------
# Report Integrity Verification
# ---------------------------------------------------------------------------

@app.get("/api/reports/verify/{report_id}")
def verify_report_integrity(report_id: str):

    try:

        result = with_retry(
            lambda: supabase.table("scam_reports")
            .select(
                "id,category,description,target_url,target_account,message_text,report_hash,blockchain_tx_hash"
            )
            .eq("id", report_id)
            .execute()
        )

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=f"Database error: {e}"
        )

    if not result.data:
        raise HTTPException(
            status_code=404,
            detail="Report not found (or not public)"
        )

    row = result.data[0]

    recomputed = compute_report_hash(
        row["description"],
        row["category"],
        row["target_url"],
        row["target_account"],
        row["message_text"]
    )

    return {
        "report_id": row["id"],
        "stored_hash": row["report_hash"],
        "recomputed_hash": recomputed,
        "intact": recomputed == row["report_hash"],
        "blockchain_tx_hash": row["blockchain_tx_hash"]
    }


# ---------------------------------------------------------------------------
# Dashboard Statistics
# ---------------------------------------------------------------------------

@app.get("/api/stats")
def get_stats():

    try:

        result = with_retry(
            lambda: supabase.table("scam_reports")
            .select("category")
            .eq("status", "verified")
            .execute()
        )

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=f"Database error: {e}"
        )

    counts = {
        "phishing": 0,
        "fake_account": 0,
        "spam": 0
    }

    for row in result.data:

        if row["category"] in counts:
            counts[row["category"]] += 1

    return {
        "total": len(result.data),
        "by_category": counts
    }


# ---------------------------------------------------------------------------
# Screenshot Upload
# ---------------------------------------------------------------------------

@app.post("/api/upload-screenshot")
async def upload_screenshot(file: UploadFile = File(...)):

    allowed = [
        "image/png",
        "image/jpeg",
        "image/webp"
    ]

    if file.content_type not in allowed:
        raise HTTPException(
            status_code=400,
            detail="Only PNG, JPEG or WEBP images are allowed"
        )

    content = await file.read()

    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(
            status_code=400,
            detail="File too large (max 5 MB)"
        )

    ext = (
        file.filename.rsplit(".", 1)[-1].lower()
        if file.filename and "." in file.filename
        else "png"
    )

    path = f"{uuid.uuid4()}.{ext}"

    try:

        with_retry(
            lambda: supabase.storage.from_("scam-evidence").upload(
                path,
                content,
                {"content-type": file.content_type}
            )
        )

        url = supabase.storage.from_("scam-evidence").get_public_url(path)

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=f"Storage error: {e}"
        )

    return {
        "screenshot_url": url
    }


# ---------------------------------------------------------------------------
# Run Application
# ---------------------------------------------------------------------------

if __name__ == "__main__":

    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )

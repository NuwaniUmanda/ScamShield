
import sys
import os
import uuid
import hashlib
import json
import time

from typing import Optional, List, Literal

# Ensure parent directory is in path
sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
)

from fastapi import FastAPI, HTTPException, UploadFile, File, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# SlowAPI Rate Limiting Imports
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address

from ai_module.ai_engine import ai_engine
from blockchain_module.ledger import blockchain_ledger
from database import supabase, supabase_admin
from logic import decide_status
from retry_helper import with_retry
from logging_config import logger


# ---------------------------------------------------------------------------
# Rate Limiting Configuration
# ---------------------------------------------------------------------------

limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["100 per minute"],
)


# ---------------------------------------------------------------------------
# FastAPI Application
# ---------------------------------------------------------------------------

app = FastAPI(
    title="ScamShield API Server",
    description="Backend API service connecting AI Scam Intelligence & Blockchain Ledger for ScamShield",
    version="1.0.0"
)

app.state.limiter = limiter

app.add_exception_handler(
    RateLimitExceeded,
    _rate_limit_exceeded_handler
)

app.add_middleware(SlowAPIMiddleware)


# ---------------------------------------------------------------------------
# CORS Configuration
# ---------------------------------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# API Request Logging Middleware
# ---------------------------------------------------------------------------

@app.middleware("http")
async def log_api_requests(request, call_next):

    start_time = time.perf_counter()

    try:

        response = await call_next(request)

        duration_ms = (
            time.perf_counter() - start_time
        ) * 1000

        route = request.scope.get("route")
        route_path = getattr(route, "path", "unmatched")

        logger.info(
            "API request completed | method=%s path=%s status_code=%s duration_ms=%.2f",
            request.method,
            route_path,
            response.status_code,
            duration_ms
        )

        return response

    except Exception:

        duration_ms = (
            time.perf_counter() - start_time
        ) * 1000

        route = request.scope.get("route")
        route_path = getattr(route, "path", "unmatched")

        logger.exception(
            "API request failed | method=%s path=%s duration_ms=%.2f",
            request.method,
            route_path,
            duration_ms
        )

        raise


# ---------------------------------------------------------------------------
# HTTP Security Headers Middleware
# ---------------------------------------------------------------------------

@app.middleware("http")
async def add_security_headers(request, call_next):

    response = await call_next(request)

    response.headers["X-Content-Type-Options"] = "nosniff"

    response.headers["X-Frame-Options"] = "DENY"

    response.headers["Referrer-Policy"] = (
        "strict-origin-when-cross-origin"
    )

    return response


# ---------------------------------------------------------------------------
# Schemas - Backend Input Validation
# ---------------------------------------------------------------------------

class AIAnalysisRequest(BaseModel):

    title: str = Field(
        min_length=1,
        max_length=200
    )

    description: str = Field(
        min_length=1,
        max_length=5000
    )

    scam_type: Optional[str] = Field(
        default="other",
        max_length=50
    )

    target_url: Optional[str] = Field(
        default=None,
        max_length=2048
    )

    target_phone: Optional[str] = Field(
        default=None,
        max_length=30
    )

    target_wallet: Optional[str] = Field(
        default=None,
        max_length=255
    )

    target_email: Optional[str] = Field(
        default=None,
        max_length=254
    )

    financial_loss: Optional[float] = Field(
        default=0.0,
        ge=0
    )


class BlockchainRecordRequest(BaseModel):

    report_id: str = Field(
        min_length=1,
        max_length=100
    )

    title: str = Field(
        min_length=1,
        max_length=200
    )

    scam_type: str = Field(
        min_length=1,
        max_length=50
    )

    risk_score: int = Field(
        ge=0,
        le=100
    )

    target_info: Optional[str] = Field(
        default="",
        max_length=2048
    )


class FullReportSubmitRequest(BaseModel):

    title: str = Field(
        min_length=1,
        max_length=200
    )

    description: str = Field(
        min_length=1,
        max_length=5000
    )

    scam_type: Literal[
        "phishing",
        "fake_account",
        "spam"
    ]

    target_url: Optional[str] = Field(
        default=None,
        max_length=2048
    )

    target_account: Optional[str] = Field(
        default=None,
        max_length=255
    )

    message_text: Optional[str] = Field(
        default=None,
        max_length=10000
    )

    screenshot_url: Optional[str] = Field(
        default=None,
        max_length=2048
    )

    target_phone: Optional[str] = Field(
        default=None,
        max_length=30
    )

    target_wallet: Optional[str] = Field(
        default=None,
        max_length=255
    )

    target_email: Optional[str] = Field(
        default=None,
        max_length=254
    )

    financial_loss: Optional[float] = Field(
        default=0.0,
        ge=0
    )

    evidence_urls: Optional[List[str]] = Field(
        default_factory=list,
        max_length=10
    )


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

    logger.info("Health check endpoint accessed")

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

    logger.info(
        "AI analysis requested | scam_type=%s",
        req.scam_type
    )

    try:

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

        logger.info("AI analysis completed successfully")

        return result

    except Exception:

        logger.exception("AI analysis failed")

        raise HTTPException(
            status_code=500,
            detail="AI analysis failed"
        )


# ---------------------------------------------------------------------------
# Blockchain
# ---------------------------------------------------------------------------

@app.post("/api/blockchain/record")
def record_on_blockchain(req: BlockchainRecordRequest):

    logger.info(
        "Blockchain recording requested | report_id=%s",
        req.report_id
    )

    try:

        result = blockchain_ledger.record_scam_on_chain(
            report_id=req.report_id,
            title=req.title,
            scam_type=req.scam_type,
            risk_score=req.risk_score,
            target_info=req.target_info or ""
        )

        logger.info(
            "Blockchain recording completed | report_id=%s",
            req.report_id
        )

        return result

    except Exception:

        logger.exception(
            "Blockchain recording failed | report_id=%s",
            req.report_id
        )

        raise HTTPException(
            status_code=500,
            detail="Blockchain recording failed"
        )


@app.get("/api/blockchain/verify/{tx_hash}")
def verify_blockchain_hash(tx_hash: str):

    verification = blockchain_ledger.verify_hash(tx_hash)

    if not verification.get("is_valid"):

        logger.warning("Blockchain hash verification failed")

        raise HTTPException(
            status_code=404,
            detail=verification.get("message", "Hash invalid")
        )

    logger.info("Blockchain hash verified successfully")

    return verification


# ---------------------------------------------------------------------------
# Submit Scam Report - Pending Blockchain Workflow
# ---------------------------------------------------------------------------

@app.post("/api/reports/submit")
def submit_report(req: FullReportSubmitRequest):

    """
    1. Analyze report using AI.
    2. Check for duplicate reports.
    3. Save report to Supabase.
    4. Keep verified candidates as pending_blockchain.
    5. Record verified candidates on blockchain.
    6. Update database after successful blockchain recording.
    """

    logger.info(
        "Scam report submission started | category=%s",
        req.scam_type
    )

    # -----------------------------------------------------------------------
    # Prepare AI Description
    # -----------------------------------------------------------------------

    ai_description = req.description

    if req.message_text:
        ai_description += " " + req.message_text

    if req.target_account:
        ai_description += " " + req.target_account

    # -----------------------------------------------------------------------
    # AI Analysis
    # -----------------------------------------------------------------------

    try:

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

    except Exception:

        logger.exception("AI analysis failed during report submission")

        raise HTTPException(
            status_code=500,
            detail="AI analysis failed"
        )

    status = decide_status(
        ai_result["confidence"],
        ai_result["risk_score"]
    )

    # -----------------------------------------------------------------------
    # Generate Report ID and Hash
    # -----------------------------------------------------------------------

    report_id = str(uuid.uuid4())

    report_hash = compute_report_hash(
        req.description,
        req.scam_type,
        req.target_url,
        req.target_account,
        req.message_text
    )

    # -----------------------------------------------------------------------
    # Duplicate Report Detection
    # -----------------------------------------------------------------------

    try:

        duplicate_result = with_retry(
            lambda: supabase_admin.table("scam_reports")
            .select("id,status,created_at")
            .eq("report_hash", report_hash)
            .eq("is_duplicate", False)
            .limit(1)
            .execute()
        )

    except Exception:

        logger.exception(
            "Duplicate report check failed | report_id=%s",
            report_id
        )

        raise HTTPException(
            status_code=500,
            detail="Duplicate report check failed"
        )

    if duplicate_result.data:

        existing = duplicate_result.data[0]

        logger.warning(
            "Duplicate report detected | existing_report_id=%s",
            existing["id"]
        )

        raise HTTPException(
            status_code=409,
            detail={
                "message": "An identical report already exists",
                "existing_report_id": existing["id"],
                "existing_status": existing["status"]
            }
        )

    # -----------------------------------------------------------------------
    # Initial Database Status
    # -----------------------------------------------------------------------

    initial_status = (
        "pending_blockchain"
        if status == "verified"
        else "suspicious"
    )

    # -----------------------------------------------------------------------
    # Complete Report Data Mapping
    # -----------------------------------------------------------------------

    row = {
        "id": report_id,
        "title": req.title,
        "category": req.scam_type,
        "description": req.description,
        "target_url": req.target_url,
        "target_account": req.target_account,
        "target_phone": req.target_phone,
        "target_wallet": req.target_wallet,
        "target_email": req.target_email,
        "message_text": req.message_text,
        "screenshot_url": req.screenshot_url,
        "evidence_urls": req.evidence_urls or [],
        "risk_score": ai_result["risk_score"],
        "confidence": ai_result["confidence"],
        "ai_analysis": ai_result,
        "status": initial_status,
        "blockchain_tx_hash": None,
        "report_hash": report_hash,
        "is_duplicate": False
    }

    # Preserve original database insertion data
    insert_row = row.copy()

    # -----------------------------------------------------------------------
    # Save Report Before Blockchain Recording
    # -----------------------------------------------------------------------

    try:

        with_retry(
            lambda: supabase_admin.table("scam_reports")
            .insert(insert_row, returning="minimal")
            .execute()
        )

        logger.info(
            "Report saved to database | report_id=%s status=%s",
            report_id,
            initial_status
        )

    except Exception as e:

        error_code = getattr(e, "code", None)

        if error_code == "23505":

            logger.warning(
                "Duplicate database constraint violation | report_id=%s",
                report_id
            )

            raise HTTPException(
                status_code=409,
                detail={
                    "message": "An identical report already exists",
                    "report_hash": report_hash
                }
            )

        logger.exception(
            "Database report insertion failed | report_id=%s",
            report_id
        )

        raise HTTPException(
            status_code=500,
            detail="Database report insertion failed"
        )

    # Separate copy for final API response
    response_row = row.copy()

    # -----------------------------------------------------------------------
    # Blockchain Recording
    # -----------------------------------------------------------------------

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

            logger.info(
                "Blockchain recording succeeded | report_id=%s",
                report_id
            )

        except Exception:

            logger.exception(
                "Blockchain recording failed | report_id=%s",
                report_id
            )

            raise HTTPException(
                status_code=502,
                detail={
                    "message": (
                        "Report saved, but blockchain recording failed. "
                        "Report remains pending."
                    ),
                    "report_id": report_id
                }
            )

        # -------------------------------------------------------------------
        # Update Database After Blockchain Success
        # -------------------------------------------------------------------

        try:

            with_retry(
                lambda: supabase_admin.table("scam_reports")
                .update({
                    "status": "verified",
                    "blockchain_tx_hash": tx_hash
                })
                .eq("id", report_id)
                .eq("status", "pending_blockchain")
                .execute()
            )

            logger.info(
                "Database updated after blockchain success | report_id=%s",
                report_id
            )

        except Exception:

            logger.exception(
                "Database update failed after blockchain recording | report_id=%s",
                report_id
            )

            raise HTTPException(
                status_code=500,
                detail={
                    "message": (
                        "Blockchain recording succeeded, "
                        "but database update failed. "
                        "Report needs reconciliation."
                    ),
                    "report_id": report_id,
                    "blockchain_tx_hash": tx_hash
                }
            )

        # Update response copy only
        response_row["status"] = "verified"
        response_row["blockchain_tx_hash"] = tx_hash

    else:

        logger.info(
            "Report classified as suspicious | report_id=%s",
            report_id
        )

    # -----------------------------------------------------------------------
    # Final Response
    # -----------------------------------------------------------------------

    logger.info(
        "Report submission completed | report_id=%s status=%s",
        report_id,
        status
    )

    return {
        "status": status,
        "ai_result": ai_result,
        "saved": [response_row]
    }


# ---------------------------------------------------------------------------
# Public Scam Search - Query Parameter Validation
# ---------------------------------------------------------------------------

@app.get("/api/reports/search")
def search_reports(
    url: Optional[str] = Query(
        default=None,
        min_length=1,
        max_length=2048
    ),
    account: Optional[str] = Query(
        default=None,
        min_length=1,
        max_length=255
    )
):

    if not url and not account:

        logger.warning("Scam search requested without parameters")

        raise HTTPException(
            status_code=400,
            detail="Provide url or account to search"
        )

    try:

        query = supabase.table("scam_reports").select(
            "id,category,target_url,target_account,screenshot_url,"
            "risk_score,status,blockchain_tx_hash,report_hash,created_at"
        ).eq("status", "verified")

        if url:
            query = query.ilike("target_url", f"%{url}%")

        if account:
            query = query.ilike("target_account", f"%{account}%")

        result = with_retry(lambda: query.execute())

        logger.info(
            "Scam search completed | result_count=%s",
            len(result.data)
        )

    except Exception:

        logger.exception("Scam search database query failed")

        raise HTTPException(
            status_code=500,
            detail="Database search failed"
        )

    return {
        "found": len(result.data) > 0,
        "count": len(result.data),
        "results": result.data
    }


# ---------------------------------------------------------------------------
# Suspicious Reports - Query Parameter Validation
# ---------------------------------------------------------------------------

@app.get("/api/reports/suspicious")
def list_suspicious_reports(
    limit: int = Query(
        default=20,
        ge=1,
        le=100
    )
):

    try:

        result = with_retry(
            lambda: supabase.table("suspicious_reports_public")
            .select("id,category,risk_score,created_at")
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )

        logger.info(
            "Suspicious reports retrieved | count=%s",
            len(result.data)
        )

    except Exception:

        logger.exception("Suspicious reports query failed")

        raise HTTPException(
            status_code=500,
            detail="Suspicious reports query failed"
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
                "id,category,description,target_url,target_account,"
                "message_text,report_hash,blockchain_tx_hash"
            )
            .eq("id", report_id)
            .execute()
        )

    except Exception:

        logger.exception(
            "Report integrity database query failed | report_id=%s",
            report_id
        )

        raise HTTPException(
            status_code=500,
            detail="Report verification query failed"
        )

    if not result.data:

        logger.warning(
            "Report not found during integrity verification | report_id=%s",
            report_id
        )

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

    is_intact = recomputed == row["report_hash"]

    if is_intact:

        logger.info(
            "Report integrity verified | report_id=%s",
            report_id
        )

    else:

        logger.warning(
            "Report integrity check failed | report_id=%s",
            report_id
        )

    return {
        "report_id": row["id"],
        "stored_hash": row["report_hash"],
        "recomputed_hash": recomputed,
        "intact": is_intact,
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

    except Exception:

        logger.exception("Dashboard statistics query failed")

        raise HTTPException(
            status_code=500,
            detail="Dashboard statistics query failed"
        )

    counts = {
        "phishing": 0,
        "fake_account": 0,
        "spam": 0
    }

    for row in result.data:

        if row["category"] in counts:
            counts[row["category"]] += 1

    logger.info(
        "Dashboard statistics generated | total=%s",
        len(result.data)
    )

    return {
        "total": len(result.data),
        "by_category": counts
    }


# ---------------------------------------------------------------------------
# Screenshot Upload - Secure File Signature Validation
# ---------------------------------------------------------------------------

@app.post("/api/upload-screenshot")
async def upload_screenshot(file: UploadFile = File(...)):

    try:

        # Read only up to 5 MB + 1 byte
        content = await file.read(5 * 1024 * 1024 + 1)

        # Check maximum file size
        if len(content) > 5 * 1024 * 1024:

            logger.warning("Screenshot upload rejected: file too large")

            raise HTTPException(
                status_code=400,
                detail="File too large (max 5 MB)"
            )

        # Detect PNG signature
        if content.startswith(b"\x89PNG\r\n\x1a\n"):

            extension = "png"
            detected_content_type = "image/png"

        # Detect JPEG signature
        elif content.startswith(b"\xff\xd8\xff"):

            extension = "jpg"
            detected_content_type = "image/jpeg"

        # Detect WEBP signature
        elif (
            len(content) >= 12
            and content[0:4] == b"RIFF"
            and content[8:12] == b"WEBP"
        ):

            extension = "webp"
            detected_content_type = "image/webp"

        else:

            logger.warning("Screenshot upload rejected: invalid image format")

            raise HTTPException(
                status_code=400,
                detail=(
                    "Invalid image file. "
                    "Upload a real PNG, JPEG or WEBP image"
                )
            )

        # Generate unique filename
        path = f"{uuid.uuid4()}.{extension}"

        try:

            with_retry(
                lambda: supabase.storage.from_("scam-evidence").upload(
                    path,
                    content,
                    {"content-type": detected_content_type}
                )
            )

            url = supabase.storage.from_(
                "scam-evidence"
            ).get_public_url(path)

            logger.info(
                "Screenshot uploaded successfully | file_type=%s",
                detected_content_type
            )

        except Exception:

            logger.exception("Screenshot storage upload failed")

            raise HTTPException(
                status_code=500,
                detail="Screenshot upload failed"
            )

        return {
            "screenshot_url": url
        }

    finally:

        await file.close()


# ---------------------------------------------------------------------------
# Run Application
# ---------------------------------------------------------------------------

if __name__ == "__main__":

    import uvicorn

    logger.info("Starting ScamShield Backend API")

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )

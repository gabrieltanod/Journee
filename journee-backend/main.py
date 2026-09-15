"""
Journee Backend — Gemini Audit Proxy
--------------------------------------
Purpose: Remove the "bring your own Gemini API key" friction for Journee users.
The iOS app sends only AGGREGATED, ANONYMOUS cycle stats (no raw transactions,
no user identity) — this server forwards them to Gemini using YOUR key and
returns the 3-bullet audit.

Chapter 1 scope: local-only, in-memory rate limiting. No database yet
(that's Chapter 2) and no cloud deployment yet (Chapter 3).
"""

import os
import time
from collections import defaultdict
from typing import Dict, List

from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel, Field
import httpx

app = FastAPI(title="Journee Backend", version="0.1.0")

# ---------------------------------------------------------------------------
# Config (Chapter 3 will move this to real environment secrets on Azure)
# ---------------------------------------------------------------------------
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "gemini-3.5-flash:generateContent"
)

# Simple in-memory rate limiter: {device_id: [timestamps]}
# NOTE: this resets whenever the server restarts. Chapter 2 replaces this
# with a real database so it persists.
RATE_LIMIT_WINDOW_SECONDS = 60 * 60  # 1 hour
RATE_LIMIT_MAX_REQUESTS = 5          # max audits per device per hour
request_log: Dict[str, List[float]] = defaultdict(list)


# ---------------------------------------------------------------------------
# Request/response schemas
# ---------------------------------------------------------------------------
class CycleStats(BaseModel):
    """Aggregated, anonymous data the Swift app already computes locally.
    No transaction-level detail, no notes, no wallet names — just numbers."""

    income: float = Field(..., description="Total income this cycle, in IDR")
    expenses: float = Field(..., description="Total expenses this cycle, in IDR")
    budget: float = Field(..., description="Monthly budget target, in IDR")
    daily_average: float = Field(..., description="Average daily spend so far")
    days_elapsed: int = Field(..., ge=0)
    days_total: int = Field(..., gt=0)
    category_breakdown: Dict[str, float] = Field(
        default_factory=dict,
        description="Category name -> amount spent, e.g. {'Food': 500000}",
    )


class AuditResponse(BaseModel):
    audit_text: str


# ---------------------------------------------------------------------------
# Rate limiting helper
# ---------------------------------------------------------------------------
def check_rate_limit(device_id: str) -> None:
    now = time.time()
    window_start = now - RATE_LIMIT_WINDOW_SECONDS

    # Drop timestamps older than the window
    request_log[device_id] = [t for t in request_log[device_id] if t > window_start]

    if len(request_log[device_id]) >= RATE_LIMIT_MAX_REQUESTS:
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Try again later.",
        )

    request_log[device_id].append(now)


# ---------------------------------------------------------------------------
# Prompt builder — mirrors the structured prompt Journee already uses
# ---------------------------------------------------------------------------
def build_prompt(stats: CycleStats) -> str:
    breakdown_lines = "\n".join(
        f"- {name}: Rp{amount:,.0f}" for name, amount in stats.category_breakdown.items()
    )
    return f"""
You are a financial audit assistant. Given this spending cycle data, respond
with EXACTLY 3 bullet points, no more, no less:
1. One critical budget leak or spending velocity trend
2. One positive savings metric
3. One actionable adjustment for the next cycle

Cycle data:
- Income: Rp{stats.income:,.0f}
- Expenses: Rp{stats.expenses:,.0f}
- Budget: Rp{stats.budget:,.0f}
- Daily average spend: Rp{stats.daily_average:,.0f}
- Days elapsed: {stats.days_elapsed}/{stats.days_total}

Category breakdown:
{breakdown_lines}
""".strip()


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@app.get("/health")
def health():
    """Simple check to confirm the server is running."""
    return {"status": "ok"}


@app.post("/audit", response_model=AuditResponse)
async def audit(stats: CycleStats, x_device_id: str = Header(...)):
    """
    x_device_id: a random UUID the Swift app generates once and stores
    locally (NOT tied to any account/identity). Used only for rate limiting.
    """
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Server misconfigured: no Gemini key set")

    check_rate_limit(x_device_id)

    prompt = build_prompt(stats)
    payload = {"contents": [{"parts": [{"text": prompt}]}]}

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            resp = await client.post(
                f"{GEMINI_URL}?key={GEMINI_API_KEY}",
                json=payload,
            )
            resp.raise_for_status()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=502, detail=f"Gemini error: {e}") from e
        except httpx.RequestError as e:
            raise HTTPException(status_code=503, detail=f"Network error: {e}") from e

    data = resp.json()
    try:
        text = data["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError) as e:
        raise HTTPException(status_code=502, detail="Unexpected Gemini response shape") from e

    return AuditResponse(audit_text=text)

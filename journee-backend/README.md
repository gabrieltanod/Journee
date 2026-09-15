# Journee Backend — Chapter 1: Gemini Proxy

## What this is
A minimal FastAPI server that removes the "bring your own Gemini key" friction
from Journee. The app sends aggregated, anonymous cycle stats — this server
calls Gemini with your key and returns the audit.

## Setup (PyCharm)

1. Open PyCharm → Open → select this `journee-backend` folder.
2. PyCharm will detect `requirements.txt` and prompt to create a virtual
   environment — accept it (or manually: `python -m venv .venv`).
3. Activate the venv and install dependencies:
   ```
   source .venv/bin/activate   # Mac/Linux
   pip install -r requirements.txt
   ```
4. Copy `.env.example` to `.env` and paste in your real Gemini API key:
   ```
   cp .env.example .env
   ```
5. Load the env var and run the server:
   ```
   export $(cat .env | xargs)   # Mac/Linux — loads GEMINI_API_KEY
   uvicorn main:app --reload --port 8000
   ```
6. Visit `http://127.0.0.1:8000/docs` — FastAPI auto-generates interactive
   API docs. Try the `/audit` endpoint right there, no Swift code needed yet.

## Testing it without Swift first

In the `/docs` UI, click `/audit` → "Try it out", set header `x-device-id`
to any random string (e.g. `test-device-1`), and use this example body:

```json
{
  "income": 8000000,
  "expenses": 5200000,
  "budget": 6000000,
  "daily_average": 250000,
  "days_elapsed": 20,
  "days_total": 28,
  "category_breakdown": {
    "Food & Drink": 2000000,
    "Transport": 800000,
    "Shopping": 1500000
  }
}
```

## Next steps (later chapters)
- Chapter 2: swap the in-memory rate limiter for MongoDB Atlas / Postgres
- Chapter 3: deploy this to Azure using your student credit
- Then: connect this endpoint from Swift using `URLSession`, replacing the
  direct Gemini call in Journee's AI Audit feature.

## Connecting from Swift (once the server is running)
Your Swift code will POST to `http://<your-server>/audit` with a JSON body
matching `CycleStats` above, and header `x-device-id` set to a UUID you
generate once and store in `UserDefaults` (not tied to any account).

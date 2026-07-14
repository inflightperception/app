# Perception OFP API

Small FastAPI server intended for Google Cloud Run.

## Local Run

```bash
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8080
```

Health check:

```bash
curl http://127.0.0.1:8080/
curl http://127.0.0.1:8080/health
```

Upload a PDF:

```bash
curl -F "file=@/path/to/ofp.pdf" http://127.0.0.1:8080/analyze
```

## Cloud Run

From the repository root:

```bash
gcloud run deploy perception-ofp-api \
  --source server \
  --region europe-west1 \
  --allow-unauthenticated
```

Configure `GEMINI_API_KEY` through Google Secret Manager for Cloud Run. The app
reads it from the environment at runtime and the local `.env` file is excluded
from the Docker image by `.dockerignore`.

Use `--no-allow-unauthenticated` later if the API should only be reachable by authenticated callers or other Google Cloud services.

## Authorization Direction

For a Flutter mobile/web app, the usual approach is:

1. Add Firebase Authentication or Google Cloud Identity Platform to the app.
2. After login, get the user's ID token in Flutter.
3. Send it to this API as `Authorization: Bearer <id-token>`.
4. Verify the token on the server before processing `/analyze`.

For service-to-service access inside Google Cloud, use Cloud Run IAM instead.

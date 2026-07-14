from pathlib import Path
import json
import logging
import os
import re
import time

from google import genai
from google.genai import types

from models.ofp_models import EnrouteWeatherResult

try:
    from dotenv import load_dotenv
except ImportError:
    load_dotenv = None


logger = logging.getLogger(__name__)

GEMINI_MAX_ATTEMPTS = 5
GEMINI_RETRY_WAIT_SECONDS = 1
GEMINI_ENV_PATH = Path(__file__).resolve().parents[1] / ".env"


def _load_gemini_env_file() -> None:
    if not GEMINI_ENV_PATH.exists():
        return

    if load_dotenv is not None:
        load_dotenv(GEMINI_ENV_PATH)
        return

    for line in GEMINI_ENV_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        key = key.strip()
        if key not in {"GEMINI_API_KEY", "GEMINI_MODEL"}:
            continue

        value = value.strip().strip("\"'")
        os.environ.setdefault(key, value)


_load_gemini_env_file()


def call_gemini_with_retry(client, model: str, contents, config=None):
    last_error = None

    for attempt in range(GEMINI_MAX_ATTEMPTS):
        try:
            kwargs = {
                "model": model,
                "contents": contents,
            }
            if config is not None:
                kwargs["config"] = config

            return client.models.generate_content(**kwargs)

        except Exception as exc:
            last_error = exc

            if attempt == GEMINI_MAX_ATTEMPTS - 1:
                logger.exception(
                    "Gemini API failed after %s consecutive attempts.",
                    GEMINI_MAX_ATTEMPTS,
                )
                raise

            logger.warning(
                "Gemini API error. Retrying in %s second. Attempt %s/%s. Error: %s",
                GEMINI_RETRY_WAIT_SECONDS,
                attempt + 1,
                GEMINI_MAX_ATTEMPTS,
                exc,
            )

            time.sleep(GEMINI_RETRY_WAIT_SECONDS)

    raise last_error


def clean_gemini_json_response(text: str) -> str:
    cleaned = text.strip()
    cleaned = re.sub(r"^```json\s*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"^```\s*", "", cleaned)
    cleaned = re.sub(r"\s*```$", "", cleaned)
    return cleaned.strip()


def analyze_enroute_weather_with_gemini(
    image_paths: list[str],
    prompt_path: Path = Path("prompts/sigwx_enroute_prompt.txt"),
) -> EnrouteWeatherResult:
    if not image_paths:
        return EnrouteWeatherResult(
            manual_review_required=True,
            reason="No chart images extracted.",
        )

    if not prompt_path.exists():
        return EnrouteWeatherResult(
            manual_review_required=True,
            reason=f"Prompt file not found: {prompt_path}",
        )

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return EnrouteWeatherResult(
            manual_review_required=True,
            reason="GEMINI_API_KEY environment variable is missing.",
        )

    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

    try:
        prompt = prompt_path.read_text(encoding="utf-8")

        parts = [
            types.Part.from_text(text=prompt),
        ]

        for image_path in image_paths:
            path = Path(image_path)
            if not path.exists():
                continue

            image_bytes = path.read_bytes()
            parts.append(
                types.Part.from_bytes(
                    data=image_bytes,
                    mime_type="image/png",
                )
            )

        if len(parts) == 1:
            return EnrouteWeatherResult(
                manual_review_required=True,
                reason="No valid image files found for Gemini.",
            )

        client = genai.Client(api_key=api_key)

        response = call_gemini_with_retry(
            client=client,
            model=model_name,
            contents=parts,
            config=types.GenerateContentConfig(
                temperature=0,
                response_mime_type="application/json",
            ),
        )

        raw_text = response.text or ""
        cleaned_text = clean_gemini_json_response(raw_text)
        data = json.loads(cleaned_text)

        return EnrouteWeatherResult.model_validate(data)
    except json.JSONDecodeError:
        return EnrouteWeatherResult(
            manual_review_required=True,
            reason="Gemini returned invalid JSON.",
            warnings=[raw_text if "raw_text" in locals() else "No response text"],
        )
    except Exception as exc:
        return EnrouteWeatherResult(
            manual_review_required=True,
            reason=f"Gemini API error: {str(exc)}",
        )

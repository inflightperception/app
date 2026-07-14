import os
import shutil
from pathlib import Path
from typing import Annotated
from uuid import uuid4

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from database.db import Base, engine
from routers.auth_router import router as auth_router
from services.chart_service import extract_charts_from_pdf_bytes
from services.decision_engine import calculate_extra_fuel_decision
from services.gemini_service import analyze_enroute_weather_with_gemini
from services.pdf_service import extract_raw_text_from_pdf
from services.ofp_parser_service import parse_ofp_raw_text


MAX_PDF_BYTES = 25 * 1024 * 1024

app = FastAPI(
    title="Perception OFP API",
    version="0.1.0",
    description="API server for OFP PDF analysis.",
)

Base.metadata.create_all(bind=engine)

allowed_origins = [
    origin.strip()
    for origin in os.getenv("CORS_ORIGINS", "*").split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

app.include_router(auth_router)


@app.get("/")
async def health_check() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/analyze")
async def analyze_pdf(
    file: Annotated[UploadFile, File(description="OFP PDF file")]
) -> dict[str, object]:

    if not file.filename or not file.filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=400,
            detail="Upload a PDF file."
        )

    content = await file.read()
    size_bytes = len(content)

    if size_bytes == 0:
        raise HTTPException(
            status_code=400,
            detail="The uploaded PDF is empty."
        )

    if size_bytes > MAX_PDF_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"PDF is too large. Maximum size is {MAX_PDF_BYTES // 1024 // 1024} MB.",
        )

    try:
        raw_text = extract_raw_text_from_pdf(content)
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc)
        ) from exc

    request_id = uuid4().hex
    chart_output_root = Path("tmp/charts")
    request_output_dir = chart_output_root / request_id

    try:
        parsed_ofp_data = parse_ofp_raw_text(raw_text)
        chart_extraction = extract_charts_from_pdf_bytes(
            content,
            output_root=chart_output_root,
            request_id=request_id,
        )
        chart_extraction_payload = (
            chart_extraction.model_dump()
            if hasattr(chart_extraction, "model_dump")
            else chart_extraction
        )
        chart_items = (
            chart_extraction.charts
            if hasattr(chart_extraction, "charts")
            else chart_extraction_payload.get("charts", [])
        )
        image_paths = [
            chart.output_file if hasattr(chart, "output_file") else chart.get("output_file")
            for chart in chart_items
            if (chart.output_file if hasattr(chart, "output_file") else chart.get("output_file"))
        ]
        enroute_weather = analyze_enroute_weather_with_gemini(image_paths)
        decision = calculate_extra_fuel_decision(
            enroute_weather=enroute_weather,
            taf_trend=parsed_ofp_data.taf_trend,
        )

        return {
            "status": "parsed",
            "filename": file.filename,
            "content_type": file.content_type,
            "size_bytes": size_bytes,
            "raw_text_length": len(raw_text),
            "data": parsed_ofp_data.model_dump(),
            "chart_extraction": chart_extraction_payload,
            "enroute_weather": enroute_weather.model_dump(),
            "decision": decision.model_dump(),
        }
    finally:
        shutil.rmtree(request_output_dir, ignore_errors=True)

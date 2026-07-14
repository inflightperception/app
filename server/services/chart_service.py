from pathlib import Path
import json
import re
import uuid

import fitz


CHART_SCORE_THRESHOLD = 6
DEFAULT_CHART_DPI = 250
DEFAULT_CHART_OUTPUT_ROOT = Path("tmp/charts")


def is_footer_only(text: str) -> bool:
    normalized = " ".join(text.split())
    return bool(re.fullmatch(r"Page \d+ of \d+", normalized, re.IGNORECASE))


def get_image_area_ratio(page: fitz.Page) -> float:
    page_area = page.rect.width * page.rect.height
    if page_area <= 0:
        return 0.0

    total_image_area = 0.0

    for image in page.get_images(full=True):
        xref = image[0]
        rects = page.get_image_rects(xref)

        for rect in rects:
            total_image_area += rect.width * rect.height

    return total_image_area / page_area


def analyze_chart_page(page: fitz.Page, page_number: int, total_pages: int) -> dict[str, object]:
    text = page.get_text("text").strip()
    text_upper = text.upper()

    image_area_ratio = get_image_area_ratio(page)

    is_rotated = page.rotation in [90, 270] or page.rect.width > page.rect.height
    has_large_image = image_area_ratio > 0.40
    has_little_text = len(text) < 150 or is_footer_only(text)
    is_near_end = page_number > total_pages - 15
    has_no_data_available = "NO DATA AVAILABLE" in text_upper

    score = 0
    reasons: list[str] = []

    if is_rotated:
        score += 3
        reasons.append("rotated_page")

    if has_large_image:
        score += 3
        reasons.append("large_image")

    if has_little_text:
        score += 2
        reasons.append("little_text")

    if is_near_end:
        score += 1
        reasons.append("near_end_of_pdf")

    should_extract = score >= CHART_SCORE_THRESHOLD and not has_no_data_available

    return {
        "page_number": page_number,
        "score": score,
        "should_extract": should_extract,
        "reasons": reasons,
        "rotation": page.rotation,
        "text_length": len(text),
        "image_area_ratio": round(image_area_ratio, 4),
        "has_no_data_available": has_no_data_available,
    }


def render_page_to_png(page: fitz.Page, output_path: Path, dpi: int = DEFAULT_CHART_DPI) -> tuple[int, int]:
    zoom = dpi / 72
    matrix = fitz.Matrix(zoom, zoom)

    pixmap = page.get_pixmap(matrix=matrix, alpha=False)
    pixmap.save(output_path)

    return pixmap.width, pixmap.height


def extract_charts_from_pdf_bytes(
    pdf_bytes: bytes,
    output_root: Path = DEFAULT_CHART_OUTPUT_ROOT,
    dpi: int = DEFAULT_CHART_DPI,
    request_id: str | None = None,
) -> dict[str, object]:
    request_id = request_id or uuid.uuid4().hex
    output_dir = output_root / request_id
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        document = fitz.open(stream=pdf_bytes, filetype="pdf")
    except Exception as exc:
        raise ValueError("Unable to open PDF file for chart extraction.") from exc

    charts: list[dict[str, object]] = []

    try:
        total_pages = len(document)

        for page_index in range(total_pages):
            page = document.load_page(page_index)
            page_number = page_index + 1
            page_info = analyze_chart_page(page, page_number, total_pages)

            if not page_info["should_extract"]:
                continue

            output_image_path = output_dir / f"chart_page_{page_number:03d}.png"
            width, height = render_page_to_png(page, output_image_path, dpi=dpi)

            page_info["output_file"] = str(output_image_path)
            page_info["rendered_width"] = width
            page_info["rendered_height"] = height

            charts.append(page_info)
    finally:
        document.close()

    metadata_path = output_dir / "charts_metadata.json"
    metadata_path.write_text(
        json.dumps(charts, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    return {
        "request_id": request_id,
        "output_dir": str(output_dir),
        "charts_extracted": len(charts),
        "pages": [chart["page_number"] for chart in charts],
        "charts": charts,
    }

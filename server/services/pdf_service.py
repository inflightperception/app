import fitz


def extract_raw_text_from_pdf(pdf_bytes: bytes) -> str:
    try:
        document = fitz.open(stream=pdf_bytes, filetype="pdf")
    except Exception as exc:
        raise ValueError("Unable to open PDF file.") from exc

    pages_text: list[str] = []

    for page_index in range(len(document)):
        page = document.load_page(page_index)
        page_text = page.get_text("text")

        pages_text.append(
            f"\n\n--- PAGE {page_index + 1} ---\n\n{page_text}"
        )

    document.close()

    return "\n".join(pages_text)

from models.ofp_models import AlternatesData
from utils.regex_utils import extract_all_values, extract_section_between


AIRPORT_CODE_PATTERN = r"[A-Z]{4}\s*/\s*([A-Z]{3})"


def unique_preserve_order(values: list[str]) -> list[str]:
    seen: set[str] = set()
    unique_values: list[str] = []

    for value in values:
        if value in seen:
            continue

        seen.add(value)
        unique_values.append(value)

    return unique_values


def extract_alternates(raw_text: str) -> AlternatesData:
    destination_alternates_section = extract_section_between(
        raw_text,
        "DESTINATION ALTERNATE(S)",
        "ENROUTE AIRPORT(S)",
    )
    enroute_airports_section = extract_section_between(
        raw_text,
        "ENROUTE AIRPORT(S)",
        "INTENTIONALLY LEFT BLANK",
    )

    destination_alternates = extract_all_values(
        destination_alternates_section,
        AIRPORT_CODE_PATTERN,
    )
    enroute_airports = extract_all_values(
        enroute_airports_section,
        AIRPORT_CODE_PATTERN,
    )

    return AlternatesData(
        destination_alternates=unique_preserve_order(destination_alternates),
        enroute_airports=unique_preserve_order(enroute_airports),
    )

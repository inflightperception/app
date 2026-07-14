import re
from typing import Optional


def extract_value(text: str, pattern: str, group: int = 1) -> Optional[str]:
    match = re.search(pattern, text)

    if not match:
        return None

    value = match.group(group)

    if value is None:
        return None

    return value.strip()


def extract_all_values(text: str, pattern: str, group: int = 1) -> list[str]:
    matches = re.finditer(pattern, text)

    values: list[str] = []

    for match in matches:
        value = match.group(group)

        if value:
            values.append(value.strip())

    return values


def extract_section_between(text: str, start_marker: str, end_marker: str) -> str:
    start_index = text.find(start_marker)

    if start_index == -1:
        return ""

    section_start = start_index + len(start_marker)
    end_index = text.find(end_marker, section_start)

    if end_index == -1:
        return text[section_start:]

    return text[section_start:end_index]

import re
from typing import Optional

from models.ofp_models import AirportWeatherBlock, TafTrendData
from parsers.taf_group_parser import parse_taf_groups


AIRPORT_HEADER_PATTERN = re.compile(r"(?m)^([A-Z]{4})/([A-Z]{3})\s+(.+)$")


def clean_weather_text(raw_text: str) -> str:
    cleaned_lines: list[str] = []

    for line in raw_text.splitlines():
        stripped = line.strip()

        if re.fullmatch(r"---\s*PAGE\s+\d+\s*---", stripped, flags=re.IGNORECASE):
            continue

        if re.fullmatch(r"Page\s+\d+\s+of\s+\d+", stripped, flags=re.IGNORECASE):
            continue

        if re.search(r"\bPage\s+\d+\s+of\s+\d+\b", stripped, flags=re.IGNORECASE):
            continue

        if re.fullmatch(
            r"AZ\s+\d+/\d{1,2}[A-Za-z]{3}\d{2}/[A-Z]{3}-[A-Z]{3}\s+Reg:[A-Z0-9]+\s+OFP:\d+/\d+/\d+",
            stripped,
        ):
            continue

        cleaned_lines.append(line.rstrip())

    cleaned_text = "\n".join(cleaned_lines)
    return re.sub(r"\n{3,}", "\n\n", cleaned_text).strip()


def extract_section_between(text: str, start_marker: str, end_marker: str) -> str:
    start_index = text.find(start_marker)
    if start_index == -1:
        return ""

    start_index += len(start_marker)
    end_index = text.find(end_marker, start_index)
    if end_index == -1:
        return text[start_index:].strip()

    return text[start_index:end_index].strip()


def parse_airport_weather_blocks(section_text: str) -> list[AirportWeatherBlock]:
    matches = list(AIRPORT_HEADER_PATTERN.finditer(section_text))
    weather_blocks: list[AirportWeatherBlock] = []

    for index, match in enumerate(matches):
        block_start = match.start()
        block_end = matches[index + 1].start() if index + 1 < len(matches) else len(section_text)
        raw_block = section_text[block_start:block_end].strip()
        ft_raw = extract_ft_raw(raw_block)

        weather_blocks.append(
            AirportWeatherBlock(
                icao=match.group(1),
                iata=match.group(2),
                airport_name=match.group(3).strip(),
                sa_raw=extract_sa_raw(raw_block),
                ft_raw=ft_raw,
                raw_block=raw_block or None,
                taf_groups=parse_taf_groups(ft_raw),
            )
        )

    return weather_blocks


def extract_sa_raw(block_text: str) -> Optional[str]:
    lines = block_text.splitlines()
    sa_start: Optional[int] = None
    sa_end = len(lines)

    for index, line in enumerate(lines):
        if re.match(r"^\s*SA\b", line):
            sa_start = index
            break

    if sa_start is None:
        return None

    for index in range(sa_start + 1, len(lines)):
        if re.match(r"^\s*FT\b", lines[index]):
            sa_end = index
            break

    sa_raw = "\n".join(lines[sa_start:sa_end]).strip()
    return sa_raw or None


def extract_ft_raw(block_text: str) -> Optional[str]:
    lines = block_text.splitlines()
    ft_start: Optional[int] = None

    for index, line in enumerate(lines):
        if re.match(r"^\s*FT\b", line):
            ft_start = index
            break

    if ft_start is None:
        return None

    ft_lines: list[str] = []
    for line in lines[ft_start:]:
        ft_lines.append(line)
        if "=" in line:
            break

    ft_raw = "\n".join(ft_lines).strip()
    return ft_raw or None


def extract_taf_trend_data(raw_text: str) -> TafTrendData:
    cleaned_text = clean_weather_text(raw_text)

    destination_section = extract_section_between(
        cleaned_text,
        "DESTINATION AIRPORT:",
        "DESTINATION ALTERNATE:",
    )
    destination_blocks = parse_airport_weather_blocks(destination_section)

    alternate_section = extract_section_between(
        cleaned_text,
        "DESTINATION ALTERNATE:",
        "ENROUTE AIRPORT(S):",
    )
    destination_alternates = parse_airport_weather_blocks(alternate_section)

    return TafTrendData(
        destination=destination_blocks[0] if destination_blocks else None,
        destination_alternates=destination_alternates,
    )

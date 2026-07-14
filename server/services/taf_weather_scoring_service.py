import re
from typing import Optional

from models.ofp_models import AirportWeatherBlock, TafGroup, TafTrendData


HEAVY_WEATHER_TOKENS = {"+TS", "+TSRA", "+SHRA"}
SNOW_WEATHER_TOKENS = {"SN", "SG"}
RELEVANT_WEATHER_TOKENS = {
    "TS",
    "TSRA",
    "SHRA",
    "GR",
    "FG",
    "VA",
    "PO",
    "SQ",
    "FC",
    "SS",
    "DS",
    "WS",
}


def score_taf_weather(taf_trend: TafTrendData) -> TafTrendData:
    if taf_trend is None:
        return taf_trend

    if taf_trend.destination is not None:
        taf_trend.destination = score_airport_weather_block(taf_trend.destination)

    return taf_trend


def score_airport_weather_block(airport: AirportWeatherBlock) -> AirportWeatherBlock:
    max_minutes = 0
    max_reason: Optional[str] = None
    scored_groups: list[TafGroup] = []

    for group in airport.taf_groups:
        scored_group = score_taf_group(group)
        scored_groups.append(scored_group)

        if scored_group.extra_fuel_minutes > max_minutes:
            max_minutes = scored_group.extra_fuel_minutes
            max_reason = scored_group.extra_fuel_reason

    airport.taf_groups = scored_groups
    airport.extra_fuel_minutes = max_minutes
    airport.extra_fuel_reason = max_reason

    return airport


def score_taf_group(group: TafGroup) -> TafGroup:
    group.extra_fuel_minutes = 0
    group.extra_fuel_reason = None

    if group.applicability_status != "APPLICABLE":
        return group

    visibility = extract_visibility_meters(group.conditions)

    if visibility is not None and visibility < 550:
        group.extra_fuel_minutes = 20
        group.extra_fuel_reason = "Visibilità inferiore a 550 metri"
        return group

    if has_weather_token(group.conditions, HEAVY_WEATHER_TOKENS):
        group.extra_fuel_minutes = 20
        group.extra_fuel_reason = "Fenomeno temporalesco o shower intenso"
        return group

    if has_weather_token(group.conditions, SNOW_WEATHER_TOKENS):
        group.extra_fuel_minutes = 20
        group.extra_fuel_reason = "Neve o grani di neve"
        return group

    if visibility is not None and visibility < 3000:
        group.extra_fuel_minutes = 10
        group.extra_fuel_reason = "Visibilità inferiore a 3000 metri"
        return group

    if has_weather_token(group.conditions, RELEVANT_WEATHER_TOKENS):
        group.extra_fuel_minutes = 10
        group.extra_fuel_reason = "Fenomeno meteo rilevante"
        return group

    return group


def extract_visibility_meters(conditions: Optional[str]) -> Optional[int]:
    for token in weather_tokens(conditions):
        if not re.fullmatch(r"\d{4}", token):
            continue

        if token.endswith("KT"):
            continue

        visibility = int(token)
        if 0 <= visibility <= 9999:
            return visibility

    return None


def has_weather_token(conditions: Optional[str], tokens: set[str]) -> bool:
    normalized_tokens = {token.upper() for token in tokens}

    for token in weather_tokens(conditions):
        if token in normalized_tokens:
            return True

        intensity_stripped_token = token.lstrip("-")
        if intensity_stripped_token in normalized_tokens:
            return True

    return False


def weather_tokens(conditions: Optional[str]) -> list[str]:
    if not conditions:
        return []

    return [token.strip().upper() for token in re.split(r"\s+", conditions) if token.strip()]

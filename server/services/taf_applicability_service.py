import calendar
import re
from datetime import datetime, timedelta
from typing import Optional

from models.ofp_models import TafGroup, TafTrendData


TRANSIENT_OR_SHOWER_TOKENS = {"TS", "TSRA", "SHRA", "+TS", "+TSRA", "+SHRA", "SHTS"}
PERSISTENT_WEATHER_TOKENS = {"HZ", "BR", "FG", "DU", "DZ", "RA", "RADZ", "DZRA", "SN", "SG"}


def apply_taf_applicability(
    taf_trend: TafTrendData,
    flight_date: Optional[str],
    etd: Optional[str],
    eta: Optional[str],
) -> TafTrendData:
    if taf_trend is None:
        return taf_trend

    eta_window_start, eta_window_end = build_eta_window(flight_date, etd, eta)

    if taf_trend.destination is not None:
        taf_trend.destination.taf_groups = [
            classify_group_applicability(group, eta_window_start, eta_window_end, flight_date)
            for group in taf_trend.destination.taf_groups
        ]

    return taf_trend


def parse_flight_datetime(flight_date: Optional[str], hhmm: Optional[str]) -> Optional[datetime]:
    if not flight_date or not hhmm:
        return None

    if not re.fullmatch(r"\d{4}", hhmm):
        return None

    try:
        parsed_date = datetime.strptime(flight_date, "%Y-%m-%d")
        hour = int(hhmm[:2])
        minute = int(hhmm[2:])

        if hour > 23 or minute > 59:
            return None

        return parsed_date.replace(hour=hour, minute=minute)
    except ValueError:
        return None


def build_eta_window(
    flight_date: Optional[str],
    etd: Optional[str],
    eta: Optional[str],
) -> tuple[Optional[datetime], Optional[datetime]]:
    eta_datetime = parse_flight_datetime(flight_date, eta)
    if eta_datetime is None:
        return None, None

    etd_datetime = parse_flight_datetime(flight_date, etd)
    if etd_datetime is not None and eta_datetime < etd_datetime:
        eta_datetime += timedelta(days=1)

    return eta_datetime - timedelta(hours=1), eta_datetime + timedelta(hours=1)


def parse_taf_validity_to_datetimes(
    validity: Optional[str],
    reference_date: Optional[str],
) -> tuple[Optional[datetime], Optional[datetime]]:
    if not validity or not reference_date:
        return None, None

    fm_match = re.fullmatch(r"(\d{2})(\d{2})(\d{2})", validity)
    if fm_match is not None:
        try:
            reference = datetime.strptime(reference_date, "%Y-%m-%d")
            day = int(fm_match.group(1))
            hour = int(fm_match.group(2))
            minute = int(fm_match.group(3))
            if hour > 23 or minute > 59:
                return None, None

            valid_from = resolve_taf_day_datetime(reference, day, hour, minute)
            if valid_from is None:
                return None, None

            return valid_from, valid_from + timedelta(hours=30)
        except ValueError:
            return None, None

    match = re.fullmatch(r"(\d{2})(\d{2})(\d{2})?/(\d{2})(\d{2})(\d{2})?", validity)
    if match is None:
        return None, None

    try:
        reference = datetime.strptime(reference_date, "%Y-%m-%d")
        start_day = int(match.group(1))
        start_hour = int(match.group(2))
        start_minute = int(match.group(3) or 0)
        end_day = int(match.group(4))
        end_hour = int(match.group(5))
        end_minute = int(match.group(6) or 0)

        if start_hour > 24 or end_hour > 24 or start_minute > 59 or end_minute > 59:
            return None, None

        valid_from = resolve_taf_day_datetime(reference, start_day, start_hour, start_minute)
        valid_to = resolve_taf_day_datetime(reference, end_day, end_hour, end_minute)
        if valid_from is None or valid_to is None:
            return None, None

        if valid_to <= valid_from:
            valid_to = add_month(valid_to)

        return valid_from, valid_to
    except ValueError:
        return None, None


def resolve_taf_day_datetime(
    reference: datetime,
    day: int,
    hour: int,
    minute: int = 0,
) -> Optional[datetime]:
    candidates: list[datetime] = []

    for month_offset in (-1, 0, 1):
        year = reference.year
        month = reference.month + month_offset
        if month == 0:
            month = 12
            year -= 1
        elif month == 13:
            month = 1
            year += 1

        candidate = build_day_hour_datetime(year, month, day, hour, minute)
        if candidate is not None:
            candidates.append(candidate)

    if not candidates:
        return None

    return min(candidates, key=lambda candidate: abs(candidate - reference))


def build_day_hour_datetime(
    year: int,
    month: int,
    day: int,
    hour: int,
    minute: int = 0,
) -> Optional[datetime]:
    if hour == 24:
        hour = 0
        add_day = True
    else:
        add_day = False

    try:
        value = datetime(year, month, day, hour, minute)
    except ValueError:
        return None

    if add_day:
        value += timedelta(days=1)

    return value


def add_month(value: datetime) -> datetime:
    year = value.year
    month = value.month + 1
    if month == 13:
        month = 1
        year += 1

    max_day = calendar.monthrange(year, month)[1]
    return value.replace(year=year, month=month, day=min(value.day, max_day))


def intervals_overlap(
    start_a: Optional[datetime],
    end_a: Optional[datetime],
    start_b: Optional[datetime],
    end_b: Optional[datetime],
) -> bool:
    if start_a is None or end_a is None or start_b is None or end_b is None:
        return False

    return start_a < end_b and start_b < end_a


def is_prob_tempo_group(group: TafGroup) -> bool:
    return group.group_type in {"PROB30_TEMPO", "PROB40_TEMPO"}


def is_tempo_style_group(group: TafGroup) -> bool:
    return group.group_type in {
        "TEMPO",
        "TEMPO_FM",
        "TEMPO_FM_TL",
        "PROB30",
        "PROB40",
    }


def is_becmg_style_group(group: TafGroup) -> bool:
    return group.group_type in {
        "BECMG",
        "BECMG_FM",
        "BECMG_TL",
        "BECMG_FM_TL",
    }


def is_fm_alone_group(group: TafGroup) -> bool:
    return group.group_type == "FM"


def is_becmg_at_group(group: TafGroup) -> bool:
    return group.group_type == "BECMG_AT"


def contains_transient_or_shower_weather(conditions: Optional[str]) -> bool:
    return any(token in TRANSIENT_OR_SHOWER_TOKENS for token in weather_tokens(conditions))


def contains_persistent_weather(conditions: Optional[str]) -> bool:
    tokens = weather_tokens(conditions)
    normalized_tokens = [token.lstrip("+-") for token in tokens]
    if any(token in PERSISTENT_WEATHER_TOKENS for token in normalized_tokens):
        return True

    for token in normalized_tokens:
        if re.fullmatch(r"\d{4}", token) and int(token) < 3000:
            return True

    return False


def weather_tokens(conditions: Optional[str]) -> list[str]:
    if not conditions:
        return []

    return [token.strip() for token in re.split(r"\s+", conditions.upper()) if token.strip()]


def classify_group_applicability(
    group: TafGroup,
    eta_window_start: Optional[datetime],
    eta_window_end: Optional[datetime],
    reference_date: Optional[str],
) -> TafGroup:
    group.extra_fuel_minutes = 0
    group.extra_fuel_reason = None

    valid_from, valid_to = parse_taf_validity_to_datetimes(group.validity, reference_date)
    if valid_from is not None:
        group.valid_from_utc = valid_from.isoformat()
    if valid_to is not None:
        group.valid_to_utc = valid_to.isoformat()

    if valid_from is None or valid_to is None:
        group.overlaps_eta_window = None
        group.applicability_status = "UNKNOWN"
        group.applicability_reason = "Unable to parse TAF group validity."
        return group

    if not intervals_overlap(valid_from, valid_to, eta_window_start, eta_window_end):
        group.overlaps_eta_window = False
        group.applicability_status = "NON_APPLICABLE"
        group.applicability_reason = "TAF group outside ETA ±1h window."
        return group

    group.overlaps_eta_window = True

    if is_prob_tempo_group(group):
        group.applicability_status = "IGNORABLE"
        group.applicability_reason = "PROB TEMPO group is ignorable by specification."
        return group

    if is_tempo_style_group(group) and contains_transient_or_shower_weather(group.conditions):
        group.applicability_status = "IGNORABLE"
        group.applicability_reason = "Transient/shower weather under TEMPO-style group is ignorable by specification."
        return group

    if is_tempo_style_group(group) and contains_persistent_weather(group.conditions):
        group.applicability_status = "APPLICABLE"
        group.applicability_reason = "Persistent weather under TEMPO-style group inside ETA ±1h window."
        return group

    if is_fm_alone_group(group) or is_becmg_at_group(group):
        group.applicability_status = "APPLICABLE"
        group.applicability_reason = "TAF change group overlaps ETA ±1h window."
        return group

    if group.group_type == "INITIAL" or is_becmg_style_group(group):
        group.applicability_status = "APPLICABLE"
        group.applicability_reason = "TAF group overlaps ETA ±1h window."
        return group

    group.applicability_status = "UNKNOWN"
    group.applicability_reason = "TAF group could not be classified."
    return group

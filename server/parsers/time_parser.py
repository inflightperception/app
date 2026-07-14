from typing import Optional

from models.ofp_models import TimeData
from utils.regex_utils import extract_value


def hh_dot_mm_to_minutes(value: Optional[str]) -> Optional[int]:
    if value is None:
        return None

    parts = value.split(".")
    if len(parts) != 2:
        return None

    try:
        hours = int(parts[0])
        minutes = int(parts[1])
    except ValueError:
        return None

    return hours * 60 + minutes


def hhmm_add_minutes(value: Optional[str], minutes_to_add: int) -> Optional[str]:
    if value is None or len(value) != 4 or not value.isdigit():
        return None

    hours = int(value[:2])
    minutes = int(value[2:])
    total_minutes = (hours * 60 + minutes + minutes_to_add) % (24 * 60)

    new_hours = total_minutes // 60
    new_minutes = total_minutes % 60

    return f"{new_hours:02d}{new_minutes:02d}"


def extract_time_data(raw_text: str) -> TimeData:
    taxi_time = extract_value(raw_text, r"TAXI\s+\d+\s+(\d{2}\.\d{2})")
    plntof_time = extract_value(raw_text, r"PLNTOF\s+\d+\s+(\d{2}\.\d{2})")

    taxi_minutes = hh_dot_mm_to_minutes(taxi_time)
    plntof_minutes = hh_dot_mm_to_minutes(plntof_time)

    block_time_minutes = None
    if taxi_minutes is not None and plntof_minutes is not None:
        block_time_minutes = taxi_minutes + plntof_minutes

    etd = extract_value(raw_text, r"\(\d+\.\d+\)\s+(\d{4})/\d{4}")
    eta = extract_value(raw_text, r"\(\d+\.\d+\)\s+\d{4}/\d{4}\s+(\d{4})/\d{4}")

    return TimeData(
        taxi_time=taxi_time,
        taxi_minutes=taxi_minutes,
        plntof_time=plntof_time,
        plntof_minutes=plntof_minutes,
        block_time_minutes=block_time_minutes,
        etd=etd,
        eta=eta,
        eta_window_start=hhmm_add_minutes(eta, -60),
        eta_window_end=hhmm_add_minutes(eta, 60),
    )

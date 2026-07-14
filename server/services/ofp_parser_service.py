from models.ofp_models import ParsedOfpData
from parsers.alternates_parser import extract_alternates
from parsers.flight_identification_parser import extract_flight_identification
from parsers.taf_trend_parser import extract_taf_trend_data
from parsers.time_parser import extract_time_data
from services.taf_applicability_service import apply_taf_applicability
from services.taf_weather_scoring_service import score_taf_weather


def parse_ofp_raw_text(raw_text: str) -> ParsedOfpData:
    flight_identification = extract_flight_identification(raw_text)
    alternates = extract_alternates(raw_text)
    times = extract_time_data(raw_text)
    taf_trend = extract_taf_trend_data(raw_text)
    taf_trend = apply_taf_applicability(
        taf_trend=taf_trend,
        flight_date=flight_identification.date,
        etd=times.etd,
        eta=times.eta,
    )
    taf_trend = score_taf_weather(taf_trend)

    return ParsedOfpData(
        flight_identification=flight_identification,
        alternates=alternates,
        times=times,
        taf_trend=taf_trend,
    )

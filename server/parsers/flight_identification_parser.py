import re

from models.ofp_models import FlightIdentificationData
from utils.regex_utils import extract_value


def extract_flight_identification(raw_text: str) -> FlightIdentificationData:
    flight_number = extract_value(raw_text, r"(AZ\s*\d{4})")

    if flight_number:
        flight_number = flight_number.replace(" ", "")

    route_match = re.search(r"([A-Z]{3})-([A-Z]{3})", raw_text)

    departure = route_match.group(1).strip() if route_match else None
    destination = route_match.group(2).strip() if route_match else None

    date = extract_value(raw_text, r"(\d{4}-\d{2}-\d{2})")
    ofp_version = extract_value(raw_text, r"OFP:(\d+/\d+/\d+)")

    return FlightIdentificationData(
        flight_number=flight_number,
        departure=departure,
        destination=destination,
        date=date,
        ofp_version=ofp_version,
    )

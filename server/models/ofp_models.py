from typing import Optional

from pydantic import BaseModel, Field


class FlightIdentificationData(BaseModel):
    flight_number: Optional[str] = None
    departure: Optional[str] = None
    destination: Optional[str] = None
    date: Optional[str] = None
    ofp_version: Optional[str] = None


class AlternatesData(BaseModel):
    destination_alternates: list[str] = Field(default_factory=list)
    enroute_airports: list[str] = Field(default_factory=list)


class TimeData(BaseModel):
    taxi_time: Optional[str] = None
    taxi_minutes: Optional[int] = None
    plntof_time: Optional[str] = None
    plntof_minutes: Optional[int] = None
    block_time_minutes: Optional[int] = None
    etd: Optional[str] = None
    eta: Optional[str] = None
    eta_window_start: Optional[str] = None
    eta_window_end: Optional[str] = None


class TafGroup(BaseModel):
    group_type: str
    issue_time: Optional[str] = None
    validity: Optional[str] = None
    raw: str
    conditions: Optional[str] = None
    valid_from_utc: Optional[str] = None
    valid_to_utc: Optional[str] = None
    overlaps_eta_window: Optional[bool] = None
    applicability_status: Optional[str] = None
    applicability_reason: Optional[str] = None
    extra_fuel_minutes: int = 0
    extra_fuel_reason: Optional[str] = None


class AirportWeatherBlock(BaseModel):
    icao: Optional[str] = None
    iata: Optional[str] = None
    airport_name: Optional[str] = None
    sa_raw: Optional[str] = None
    ft_raw: Optional[str] = None
    raw_block: Optional[str] = None
    taf_groups: list[TafGroup] = Field(default_factory=list)
    extra_fuel_minutes: int = 0
    extra_fuel_reason: Optional[str] = None


class TafTrendData(BaseModel):
    destination: Optional[AirportWeatherBlock] = None
    destination_alternates: list[AirportWeatherBlock] = Field(default_factory=list)


class ParsedOfpData(BaseModel):
    flight_identification: FlightIdentificationData
    alternates: AlternatesData
    times: TimeData
    taf_trend: TafTrendData


class RelevantPhenomenon(BaseModel):
    raw_label: Optional[str] = None
    phenomenon: Optional[str] = None
    coverage: Optional[str] = None
    top_fl: Optional[int] = None
    base_fl: Optional[int] = None
    position_relative_to_route: Optional[str] = None
    is_relevant: bool = False


class EnrouteWeatherResult(BaseModel):
    is_significant_weather_chart: bool = False
    route_visible: Optional[bool] = None
    has_significant_enroute_wx: bool = False
    weather_area_intersects_route: bool = False
    weather_area_close_to_route: bool = False

    has_ocnl_cb: bool = False
    top_fl: Optional[int] = None
    top_greater_than_fl250: bool = False

    has_tropical_cyclone_or_hurricane: bool = False
    distance_from_cyclone_nm: Optional[int] = None
    cyclone_within_120nm: bool = False

    extra_fuel_enroute_required: bool = False
    extra_fuel_enroute_minutes: int = 0

    relevant_phenomena: list[RelevantPhenomenon] = Field(default_factory=list)

    confidence: float = 0.0
    manual_review_required: bool = False
    reason: Optional[str] = None
    warnings: list[str] = Field(default_factory=list)


class ExtraFuelBreakdownItem(BaseModel):
    area: str
    source: str
    minutes: int
    reason: Optional[str] = None
    confidence: Optional[float] = None


class ExtraFuelDecision(BaseModel):
    extra_fuel_total_minutes: int = 0
    manual_review_required: bool = False
    breakdown: list[ExtraFuelBreakdownItem] = Field(default_factory=list)

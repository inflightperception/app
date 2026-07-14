from models.ofp_models import (
    AirportWeatherBlock,
    EnrouteWeatherResult,
    ExtraFuelBreakdownItem,
    ExtraFuelDecision,
    TafTrendData,
)


def calculate_extra_fuel_decision(
    enroute_weather: EnrouteWeatherResult,
    taf_trend: TafTrendData | None = None,
) -> ExtraFuelDecision:
    breakdown: list[ExtraFuelBreakdownItem] = []

    if (
        enroute_weather.extra_fuel_enroute_required
        and enroute_weather.extra_fuel_enroute_minutes > 0
    ):
        breakdown.append(
            ExtraFuelBreakdownItem(
                area="ENROUTE",
                source="SIGWX_CHART",
                minutes=enroute_weather.extra_fuel_enroute_minutes,
                reason=enroute_weather.reason,
                confidence=enroute_weather.confidence,
            )
        )

    if taf_trend and taf_trend.destination:
        destination = taf_trend.destination

        if destination.extra_fuel_minutes > 0:
            breakdown.append(
                ExtraFuelBreakdownItem(
                    area="DESTINATION",
                    source="TAF",
                    minutes=destination.extra_fuel_minutes,
                    reason=destination.extra_fuel_reason,
                    confidence=None,
                )
            )

    total_minutes = sum(item.minutes for item in breakdown)

    return ExtraFuelDecision(
        extra_fuel_total_minutes=total_minutes,
        manual_review_required=enroute_weather.manual_review_required,
        breakdown=breakdown,
    )


def get_highest_scoring_alternate(
    taf_trend: TafTrendData | None,
) -> AirportWeatherBlock | None:
    if not taf_trend or not taf_trend.destination_alternates:
        return None

    best = max(
        taf_trend.destination_alternates,
        key=lambda airport: airport.extra_fuel_minutes,
    )

    if best.extra_fuel_minutes <= 0:
        return None

    return best

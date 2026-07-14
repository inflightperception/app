import sys
import unittest
from pathlib import Path


SERVER_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SERVER_DIR))

from models.ofp_models import (
    AirportWeatherBlock,
    EnrouteWeatherResult,
    TafGroup,
    TafTrendData,
)
from services.decision_engine import calculate_extra_fuel_decision
from services.taf_applicability_service import apply_taf_applicability
from services.taf_weather_scoring_service import score_taf_weather


class DestinationOnlyTrendTest(unittest.TestCase):
    def test_decision_uses_destination_taf_only(self):
        taf_trend = TafTrendData(
            destination=AirportWeatherBlock(
                icao="DEST",
                extra_fuel_minutes=10,
                extra_fuel_reason="Destination weather",
            ),
            destination_alternates=[
                AirportWeatherBlock(
                    icao="ALTN",
                    extra_fuel_minutes=20,
                    extra_fuel_reason="Alternate weather",
                )
            ],
        )

        decision = calculate_extra_fuel_decision(
            enroute_weather=EnrouteWeatherResult(),
            taf_trend=taf_trend,
        )

        self.assertEqual(decision.extra_fuel_total_minutes, 10)
        self.assertEqual(len(decision.breakdown), 1)
        self.assertEqual(decision.breakdown[0].area, "DESTINATION")
        self.assertEqual(decision.breakdown[0].minutes, 10)
        self.assertNotIn("ALTERNATE", {item.area for item in decision.breakdown})

    def test_apply_taf_applicability_classifies_destination_only(self):
        taf_trend = TafTrendData(
            destination=AirportWeatherBlock(
                icao="DEST",
                taf_groups=[
                    TafGroup(
                        group_type="BECMG",
                        validity="0610/0612",
                        raw="BECMG 0610/0612 2500 BR",
                        conditions="2500 BR",
                    )
                ],
            ),
            destination_alternates=[
                AirportWeatherBlock(
                    icao="ALTN",
                    taf_groups=[
                        TafGroup(
                            group_type="BECMG",
                            validity="0610/0612",
                            raw="BECMG 0610/0612 0400 FG",
                            conditions="0400 FG",
                        )
                    ],
                )
            ],
        )

        result = apply_taf_applicability(
            taf_trend=taf_trend,
            flight_date="2026-06-06",
            etd="0900",
            eta="1100",
        )

        self.assertEqual(result.destination.taf_groups[0].applicability_status, "APPLICABLE")
        self.assertIsNone(result.destination_alternates[0].taf_groups[0].applicability_status)
        self.assertIsNone(result.destination_alternates[0].taf_groups[0].overlaps_eta_window)

    def test_score_taf_weather_scores_destination_only(self):
        taf_trend = TafTrendData(
            destination=AirportWeatherBlock(
                icao="DEST",
                taf_groups=[
                    TafGroup(
                        group_type="BECMG",
                        validity="0610/0612",
                        raw="BECMG 0610/0612 2500 BR",
                        conditions="2500 BR",
                        applicability_status="APPLICABLE",
                    )
                ],
            ),
            destination_alternates=[
                AirportWeatherBlock(
                    icao="ALTN",
                    taf_groups=[
                        TafGroup(
                            group_type="BECMG",
                            validity="0610/0612",
                            raw="BECMG 0610/0612 0400 FG",
                            conditions="0400 FG",
                            applicability_status="APPLICABLE",
                        )
                    ],
                )
            ],
        )

        result = score_taf_weather(taf_trend)

        self.assertEqual(result.destination.extra_fuel_minutes, 10)
        self.assertEqual(result.destination.taf_groups[0].extra_fuel_minutes, 10)
        self.assertEqual(result.destination_alternates[0].extra_fuel_minutes, 0)
        self.assertEqual(result.destination_alternates[0].taf_groups[0].extra_fuel_minutes, 0)
        self.assertIsNone(result.destination_alternates[0].extra_fuel_reason)


if __name__ == "__main__":
    unittest.main()

import sys
import unittest
from pathlib import Path


SERVER_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SERVER_DIR))

from models.ofp_models import AirportWeatherBlock, TafTrendData
from parsers.taf_group_parser import parse_taf_groups
from services.taf_applicability_service import apply_taf_applicability
from services.taf_weather_scoring_service import score_taf_weather


class TafClientRulesTest(unittest.TestCase):
    def score_taf(self, taf_suffix: str, eta: str = "1100") -> AirportWeatherBlock:
        ft_raw = f"FT 060000 0600/0700 9999 SCT020 {taf_suffix}"
        airport = AirportWeatherBlock(icao="LIRF", ft_raw=ft_raw, taf_groups=parse_taf_groups(ft_raw))
        taf_trend = TafTrendData(destination=airport)

        taf_trend = apply_taf_applicability(
            taf_trend=taf_trend,
            flight_date="2026-06-06",
            etd="0900",
            eta=eta,
        )
        taf_trend = score_taf_weather(taf_trend)
        return taf_trend.destination

    def last_group(self, taf_suffix: str, eta: str = "1100"):
        airport = self.score_taf(taf_suffix, eta)
        return airport.taf_groups[-1], airport

    def test_tempo_shra_is_ignorable(self):
        group, airport = self.last_group("TEMPO 0610/0612 SHRA")

        self.assertEqual(group.group_type, "TEMPO")
        self.assertEqual(group.applicability_status, "IGNORABLE")
        self.assertEqual(group.extra_fuel_minutes, 0)
        self.assertEqual(airport.extra_fuel_minutes, 0)

    def test_tempo_fm_tl_shra_is_ignorable(self):
        group, airport = self.last_group("TEMPO FM061000 TL061200 SHRA")

        self.assertEqual(group.group_type, "TEMPO_FM_TL")
        self.assertEqual(group.validity, "061000/061200")
        self.assertEqual(group.applicability_status, "IGNORABLE")
        self.assertEqual(group.extra_fuel_minutes, 0)
        self.assertEqual(airport.extra_fuel_minutes, 0)

    def test_tempo_br_or_hz_is_applicable(self):
        br_group, _ = self.last_group("TEMPO 0610/0612 BR")
        hz_group, _ = self.last_group("TEMPO 0610/0612 HZ")

        self.assertEqual(br_group.applicability_status, "APPLICABLE")
        self.assertEqual(hz_group.applicability_status, "APPLICABLE")

    def test_prob30_tempo_shra_is_ignorable(self):
        group, airport = self.last_group("PROB30 TEMPO 0610/0612 SHRA")

        self.assertEqual(group.group_type, "PROB30_TEMPO")
        self.assertEqual(group.applicability_status, "IGNORABLE")
        self.assertEqual(group.extra_fuel_minutes, 0)
        self.assertEqual(airport.extra_fuel_minutes, 0)

    def test_becmg_is_applicable_with_no_extra_fuel(self):
        group, airport = self.last_group("BECMG 0610/0612 6000 SCT020")

        self.assertEqual(group.group_type, "BECMG")
        self.assertEqual(group.applicability_status, "APPLICABLE")
        self.assertEqual(group.extra_fuel_minutes, 0)
        self.assertIsNone(group.extra_fuel_reason)
        self.assertEqual(airport.extra_fuel_minutes, 0)

    def test_becmg_at_low_visibility_br_scores_10_minutes(self):
        group, airport = self.last_group("BECMG AT061200 2500 BR", eta="1200")

        self.assertEqual(group.group_type, "BECMG_AT")
        self.assertEqual(group.applicability_status, "APPLICABLE")
        self.assertEqual(group.extra_fuel_minutes, 10)
        self.assertEqual(group.extra_fuel_reason, "Visibilità inferiore a 3000 metri")
        self.assertEqual(airport.extra_fuel_minutes, 10)

    def test_applicable_visibility_below_550_scores_20_minutes(self):
        group, airport = self.last_group("BECMG 0610/0612 0400 FG")

        self.assertEqual(group.applicability_status, "APPLICABLE")
        self.assertEqual(group.extra_fuel_minutes, 20)
        self.assertEqual(group.extra_fuel_reason, "Visibilità inferiore a 550 metri")
        self.assertEqual(airport.extra_fuel_minutes, 20)


if __name__ == "__main__":
    unittest.main()

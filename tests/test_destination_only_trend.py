import importlib.util
from pathlib import Path


SERVER_TEST = (
    Path(__file__).resolve().parents[1]
    / "server"
    / "tests"
    / "test_destination_only_trend.py"
)

spec = importlib.util.spec_from_file_location("_server_destination_only_trend", SERVER_TEST)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

DestinationOnlyTrendTest = module.DestinationOnlyTrendTest

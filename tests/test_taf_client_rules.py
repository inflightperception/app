import importlib.util
from pathlib import Path


SERVER_TEST = (
    Path(__file__).resolve().parents[1]
    / "server"
    / "tests"
    / "test_taf_client_rules.py"
)

spec = importlib.util.spec_from_file_location("_server_taf_client_rules", SERVER_TEST)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

TafClientRulesTest = module.TafClientRulesTest

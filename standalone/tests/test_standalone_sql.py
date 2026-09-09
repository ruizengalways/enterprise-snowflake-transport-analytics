from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "sql"


class StandaloneTransportSqlTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.files = sorted(SQL_DIR.glob("*.sql"))
        cls.sql = "\n".join(path.read_text(encoding="utf-8") for path in cls.files).upper()

    def test_has_expected_portable_scripts(self) -> None:
        self.assertEqual(
            {path.name for path in self.files},
            {
                "00_setup.sql",
                "10_generate_vehicle_status.sql",
                "20_generate_vehicle_position.sql",
                "30_incremental_vehicle_status_simulator.sql",
                "90_validate.sql",
                "99_cleanup.sql",
            },
        )

    def test_has_no_enterprise_platform_dependency(self) -> None:
        for forbidden in (
            "ENTERPRISE_SNOWFLAKE_FRAMEWORK",
            "PLATFORM_CONTROL",
            "CREATE DATABASE",
            "USE DATABASE",
            "USE ROLE",
            "USE WAREHOUSE",
            "AR_TRANSPORT_",
            "WH_TRANSPORT_",
            "DEV_TRANSPORT",
            "UAT_TRANSPORT",
            "PROD_TRANSPORT",
        ):
            self.assertNotIn(forbidden, self.sql)

    def test_vehicle_status_contract_columns_are_present(self) -> None:
        status_sql = (SQL_DIR / "10_generate_vehicle_status.sql").read_text(encoding="utf-8").upper()
        for column in (
            "VEHICLE_ID",
            "STATUS",
            "DEPOT_ID",
            "ROUTE_ID",
            "SOURCE_UPDATED_AT",
            "SOURCE_OPERATION",
            "SOURCE_SEQUENCE",
            "INGESTED_AT",
        ):
            self.assertIn(column, status_sql)
        self.assertIn("'I'", status_sql)
        self.assertIn("'U'", status_sql)
        self.assertIn("'D'", status_sql)

    def test_vehicle_position_contract_columns_are_present(self) -> None:
        position_sql = (SQL_DIR / "20_generate_vehicle_position.sql").read_text(encoding="utf-8").upper()
        for column in (
            "VEHICLE_ID",
            "EVENT_TIMESTAMP",
            "LATITUDE",
            "LONGITUDE",
            "ROUTE_ID",
            "INGESTED_AT",
        ):
            self.assertIn(column, position_sql)

    def test_incremental_simulator_is_native_sql_and_stateful(self) -> None:
        simulator_sql = (SQL_DIR / "30_incremental_vehicle_status_simulator.sql").read_text(encoding="utf-8").upper()
        self.assertIn("CREATE OR REPLACE PROCEDURE DEMO_TRANSPORT.RESET_VEHICLE_STATUS_SIMULATOR()", simulator_sql)
        self.assertIn("CREATE OR REPLACE PROCEDURE DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR()", simulator_sql)
        self.assertIn("LANGUAGE SQL", simulator_sql)
        self.assertNotIn("LANGUAGE PYTHON", simulator_sql)
        self.assertIn("VEHICLE_STATUS_SIM_STATE", simulator_sql)
        self.assertIn("CURRENT_BATCH", simulator_sql)
        self.assertIn("VEHICLE_STATUS_SIM_CDC", simulator_sql)
        self.assertIn("VEHICLE_STATUS_SIM_CURRENT", simulator_sql)
        self.assertIn("'I'", simulator_sql)
        self.assertIn("'U'", simulator_sql)
        self.assertIn("'D'", simulator_sql)


if __name__ == "__main__":
    unittest.main()

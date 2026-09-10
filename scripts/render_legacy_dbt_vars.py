#!/usr/bin/env python3
"""Render transition-only dbt vars from legacy config/datasets metadata.

This compatibility adapter exists only while the pre-0.25 dbt Silver runtime remains the
comparison/reference implementation. Current Framework machine contracts are validated separately
from config/sources and source-scoped RAW contracts by `esf validate`.

Do not add new business semantics here. Delete this script with the legacy dbt Silver runtime.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

import yaml

_DATASET_KEYS = (
    "id",
    "owner_team",
    "raw_contract",
    "load",
    "materialization",
    "runtime",
    "compute",
    "quality",
)
_SOURCE_CONTRACT_KEYS = (
    "source_system",
    "entity",
    "grain",
    "business_key",
    "source_timestamp",
    "change_semantics",
    "capture",
    "cadence",
    "retention_days",
    "breaking_change_policy",
)


def _load(path: Path) -> dict:
    document = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(document, dict):
        raise ValueError(f"expected mapping in {path}")
    return document


def _snapshot(dataset_document: dict, raw_document: dict | None) -> dict[str, object]:
    dataset = dataset_document["dataset"]
    payload: dict[str, object] = {
        "dataset": {key: dataset[key] for key in _DATASET_KEYS if key in dataset},
        "dataset_schema_version": dataset_document["schema_version"],
    }
    if raw_document is not None:
        contract = raw_document["contract"]
        payload["source_contract"] = {
            key: contract[key] for key in _SOURCE_CONTRACT_KEYS if key in contract
        }
        payload["raw_contract_schema_version"] = raw_document["schema_version"]
    config_json = json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return {
        "config_schema_version": 2,
        "config_hash": hashlib.sha256(config_json.encode("utf-8")).hexdigest(),
        "config_json": config_json,
    }


def build_vars(project_root: Path) -> dict[str, object]:
    project = _load(project_root / "config" / "project.yml")["project"]
    datasets: dict[str, dict[str, object]] = {}
    snapshots: dict[str, dict[str, object]] = {}

    for path in sorted((project_root / "config" / "datasets").glob("*.y*ml")):
        document = _load(path)
        dataset = document.get("dataset")
        if not isinstance(dataset, dict) or not dataset.get("id"):
            raise ValueError(f"legacy dataset metadata missing dataset.id: {path}")

        dataset_id = str(dataset["id"])
        technical: dict[str, object] = {"schema_version": 2, **dataset}
        raw_document: dict | None = None
        raw_contract_path = dataset.get("raw_contract")
        if raw_contract_path:
            raw_document = _load(project_root / str(raw_contract_path))
            contract = raw_document["contract"]
            technical["source_system"] = contract["source_system"]
            technical["source_contract"] = {
                "grain": contract["grain"],
                "business_key": contract["business_key"],
                "source_timestamp": contract.get("source_timestamp"),
                "change_semantics": contract["change_semantics"],
            }

        datasets[dataset_id] = technical
        snapshots[dataset_id] = _snapshot(document, raw_document)

    return {
        "esf_project": {
            "code": project["code"],
            "repository": project["repository"],
            "owner_team": project["owner_team"],
        },
        "esf_datasets": datasets,
        "esf_dataset_snapshots": snapshots,
    }


def main() -> None:
    print(json.dumps(build_vars(Path.cwd()), sort_keys=True, separators=(",", ":")))


if __name__ == "__main__":
    main()

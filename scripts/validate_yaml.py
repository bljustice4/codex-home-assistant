#!/usr/bin/env python3
"""Validate Home Assistant YAML syntax while tolerating HA-specific tags."""

from __future__ import annotations

import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML is required. Install with: python3 -m pip install -r requirements.txt", file=sys.stderr)
    raise SystemExit(127)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG_DIR = PROJECT_ROOT / "config"


class HaLoader(yaml.SafeLoader):
    pass


def construct_unknown(loader: HaLoader, tag_suffix: str, node: yaml.Node):
    if isinstance(node, yaml.ScalarNode):
        return loader.construct_scalar(node)
    if isinstance(node, yaml.SequenceNode):
        return loader.construct_sequence(node)
    if isinstance(node, yaml.MappingNode):
        return loader.construct_mapping(node)
    return None


HaLoader.add_multi_constructor("!", construct_unknown)


def main() -> int:
    if not CONFIG_DIR.exists():
        print(f"Config directory does not exist: {CONFIG_DIR}", file=sys.stderr)
        return 1

    paths = sorted(
        path
        for pattern in ("*.yaml", "*.yml")
        for path in CONFIG_DIR.rglob(pattern)
        if ".storage" not in path.parts
    )

    failures: list[tuple[Path, Exception]] = []
    for path in paths:
        try:
            with path.open("r", encoding="utf-8") as handle:
                yaml.load(handle, Loader=HaLoader)
        except Exception as exc:  # noqa: BLE001 - report all parser failures with file path.
            failures.append((path, exc))

    if failures:
        print("YAML validation failed:", file=sys.stderr)
        for path, exc in failures:
            print(f"- {path.relative_to(PROJECT_ROOT)}: {exc}", file=sys.stderr)
        return 1

    print(f"YAML OK: {len(paths)} file(s) checked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

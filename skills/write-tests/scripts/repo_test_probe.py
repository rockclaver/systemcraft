#!/usr/bin/env python3
"""
Inspect a repository and emit practical testing hints:
- likely languages and frameworks
- candidate test commands
- existing coverage artifacts
- likely source and test roots
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any


MAX_RESULTS = 40
IGNORE_DIRS = {
    ".git",
    ".hg",
    ".svn",
    "node_modules",
    ".venv",
    "venv",
    "__pycache__",
    "dist",
    "build",
    ".next",
    ".turbo",
    "coverage",
    "target",
    "bin",
    "obj",
}


def load_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""


def walk_files(root: Path) -> list[Path]:
    paths: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in IGNORE_DIRS]
        for filename in filenames:
            paths.append(Path(dirpath) / filename)
    return paths


def count_suffixes(paths: list[Path]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for path in paths:
        suffix = "".join(path.suffixes[-2:]) if path.name.endswith(".d.ts") else path.suffix.lower()
        if suffix:
            counts[suffix] = counts.get(suffix, 0) + 1
    return counts


def find_named(paths: list[Path], *names: str) -> list[Path]:
    wanted = set(names)
    return [path for path in paths if path.name in wanted]


def top_entries(items: list[str], limit: int = MAX_RESULTS) -> list[str]:
    return sorted(set(items))[:limit]


def detect_from_package_json(path: Path) -> dict[str, Any]:
    data: dict[str, Any] = {}
    try:
        pkg = json.loads(load_text(path) or "{}")
    except Exception:
        return data

    scripts = pkg.get("scripts", {}) if isinstance(pkg.get("scripts"), dict) else {}
    deps = {}
    for key in ("dependencies", "devDependencies", "peerDependencies"):
        value = pkg.get(key)
        if isinstance(value, dict):
            deps.update(value)

    frameworks = []
    for dep, framework in (
        ("vitest", "vitest"),
        ("jest", "jest"),
        ("mocha", "mocha"),
        ("ava", "ava"),
        ("playwright", "playwright"),
        ("cypress", "cypress"),
        ("react", "react"),
        ("next", "next.js"),
        ("vue", "vue"),
    ):
        if dep in deps or dep in scripts:
            frameworks.append(framework)

    commands = []
    for name in ("test", "test:unit", "test:coverage", "coverage", "check"):
        if name in scripts:
            commands.append(f"npm run {name}")
    return {
        "ecosystem": "javascript",
        "frameworks": frameworks,
        "commands": commands,
    }


def detect_python(root: Path, paths: list[Path]) -> dict[str, Any]:
    files = {p.name for p in paths}
    frameworks = []
    commands = []
    if "pytest.ini" in files or "conftest.py" in files:
        frameworks.append("pytest")
    pyproject = root / "pyproject.toml"
    pyproject_text = load_text(pyproject)
    if "pytest" in pyproject_text:
        frameworks.append("pytest")
    if "unittest" in pyproject_text:
        frameworks.append("unittest")
    if "pytest" in frameworks:
        commands.extend(["pytest", "pytest --cov"])
    return {
        "ecosystem": "python",
        "frameworks": sorted(set(frameworks)),
        "commands": commands,
    } if frameworks else {}


def detect_go(paths: list[Path]) -> dict[str, Any]:
    if not any(path.name == "go.mod" for path in paths):
        return {}
    has_tests = any(path.name.endswith("_test.go") for path in paths)
    return {
        "ecosystem": "go",
        "frameworks": ["go test"] if has_tests else [],
        "commands": ["go test ./...", "go test ./... -cover"] if has_tests else [],
    }


def detect_java(paths: list[Path]) -> dict[str, Any]:
    names = {path.name for path in paths}
    if "pom.xml" in names:
        return {
            "ecosystem": "java",
            "frameworks": ["maven"],
            "commands": ["mvn test"],
        }
    if "build.gradle" in names or "build.gradle.kts" in names:
        return {
            "ecosystem": "java",
            "frameworks": ["gradle"],
            "commands": ["./gradlew test"],
        }
    return {}


def detect_rust(paths: list[Path]) -> dict[str, Any]:
    if any(path.name == "Cargo.toml" for path in paths):
        return {
            "ecosystem": "rust",
            "frameworks": ["cargo"],
            "commands": ["cargo test"],
        }
    return {}


def classify_paths(paths: list[Path], root: Path) -> tuple[list[str], list[str]]:
    source_roots: set[str] = set()
    test_roots: set[str] = set()
    for path in paths:
        rel = path.relative_to(root)
        parts = rel.parts
        if not parts:
            continue
        top = parts[0]
        name = path.name.lower()
        if top in {"src", "lib", "app", "pkg", "internal"}:
            source_roots.add(top)
        if top in {"test", "tests", "__tests__", "spec"}:
            test_roots.add(top)
        if any(token in name for token in ("_test.", ".test.", ".spec.")):
            test_roots.add(str(rel.parent))
    return top_entries(list(source_roots)), top_entries(list(test_roots))


def find_coverage_artifacts(paths: list[Path], root: Path) -> list[str]:
    matches = []
    artifact_names = {
        "lcov.info",
        "coverage-final.json",
        "coverage.xml",
        "jacoco.xml",
        ".coverage",
    }
    for path in paths:
        if path.name in artifact_names:
            matches.append(str(path.relative_to(root)))
    return top_entries(matches)


def likely_targets(paths: list[Path], root: Path) -> list[str]:
    candidates = []
    interesting_dirs = {"src", "lib", "app", "pkg", "internal"}
    for path in paths:
        rel = path.relative_to(root)
        if rel.parts and rel.parts[0] in interesting_dirs:
            name = path.name.lower()
            if name.endswith((".js", ".jsx", ".ts", ".tsx", ".py", ".go", ".rs", ".java", ".kt")):
                if not any(token in name for token in (".test.", ".spec.", "_test.")):
                    candidates.append(str(rel))
    return top_entries(candidates)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", nargs="?", default=".", help="Path to the repository root")
    args = parser.parse_args()

    root = Path(args.repo).resolve()
    paths = walk_files(root)
    suffix_counts = count_suffixes(paths)

    detections = []
    package_json_files = find_named(paths, "package.json")
    for pkg in package_json_files[:1]:
        result = detect_from_package_json(pkg)
        if result:
            detections.append(result)

    python_result = detect_python(root, paths)
    if python_result:
        detections.append(python_result)

    for detector in (detect_go, detect_java, detect_rust):
        result = detector(paths)
        if result:
            detections.append(result)

    ecosystems = [d["ecosystem"] for d in detections if d.get("ecosystem")]
    frameworks = sorted({fw for d in detections for fw in d.get("frameworks", [])})
    commands = []
    for detection in detections:
        commands.extend(detection.get("commands", []))

    source_roots, test_roots = classify_paths(paths, root)
    report = {
        "repo": str(root),
        "file_counts_by_suffix": suffix_counts,
        "ecosystems": ecosystems,
        "frameworks": frameworks,
        "candidate_test_commands": top_entries(commands),
        "source_roots": source_roots,
        "test_roots": test_roots,
        "coverage_artifacts": find_coverage_artifacts(paths, root),
        "likely_untested_targets": likely_targets(paths, root),
    }
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()

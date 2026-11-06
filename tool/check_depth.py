#!/usr/bin/env python3
"""Проверка логической вложенности в Dart-файлах монорепо.

Считает глубину управляющих конструкций (if/for/while/switch/try/catch),
а не отступы: вложенность виджетов в build не учитывается.

Запуск: python3 tool/check_depth.py [--max 3]
"""

import argparse
import os
import re
import sys

KEYWORDS = re.compile(r"^(if|for|while|switch|try)\b|\b(if|for|while|switch)\s*\(")
SKIP_DIRS = {".dart_tool", "build", ".git", "node_modules"}
ROOTS = ("lib", "labs", "packages")


def logical_depth(path):
    depth = 0
    best = 0
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.split("//")[0]
            stripped = line.strip()
            if not stripped:
                continue
            is_control = bool(KEYWORDS.search(stripped))
            best = max(best, depth + (1 if is_control else 0))
            depth = max(0, depth + line.count("{") - line.count("}"))
    return best


def dart_files():
    for root in ROOTS:
        for dirpath, dirnames, names in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
            for name in names:
                if name.endswith(".dart") and not name.endswith(".g.dart"):
                    yield os.path.join(dirpath, name)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--max", type=int, default=3)
    args = parser.parse_args()

    offenders = sorted(
        ((logical_depth(path), path) for path in dart_files()),
        reverse=True,
    )
    over = [item for item in offenders if item[0] > args.max]

    for depth, path in over:
        print(f"{path}: логическая вложенность {depth} > {args.max}")

    print(f"проверено файлов: {len(offenders)}, нарушений: {len(over)}")
    return 1 if over else 0


if __name__ == "__main__":
    sys.exit(main())

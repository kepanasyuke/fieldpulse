#!/usr/bin/env python3
"""Проверка вложенности управляющих конструкций в Dart-файлах монорепо.

Считается только вложенность if/for/while/switch/try друг в друга.
Фигурные скобки классов, методов и литералов не учитываются, поэтому
глубина 1 - это один if внутри метода, а не "класс + метод + if".

Запуск: python3 tool/check_depth.py [--max 3]
"""

import argparse
import os
import re
import sys

OPENS = re.compile(r"\b(if|for|while|switch|try)\b[^{;]*\{")
SKIP_DIRS = {".dart_tool", "build", ".git", "node_modules"}
ROOTS = ("lib", "labs", "packages", "apps")


def logical_depth(path):
    depth = 0
    best = 0
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.split("//")[0]
            opens = 1 if OPENS.search(line) else 0
            if line.strip():
                best = max(best, depth + opens)

            closes = line.count("}")
            depth = max(0, depth + opens - closes)

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
        print(f"{path}: вложенность {depth} > {args.max}")

    print(f"проверено файлов: {len(offenders)}, нарушений: {len(over)}")
    return 1 if over else 0


if __name__ == "__main__":
    sys.exit(main())

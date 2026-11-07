#!/usr/bin/env python3
"""Проверка вложенности управляющих конструкций в Dart-файлах монорепо.

Считается только вложенность if/for/while/switch/try друг в друга.
Скобки классов, тел методов, литералов и замыканий уровнем не считаются,
поэтому глубина 1 - это один if внутри метода, а 3 - предельно допустимая
цепочка вида "for -> if -> switch".

Запуск: python3 tool/check_depth.py [--max 3]
"""

import argparse
import os
import re
import sys

CONTROL = re.compile(r"^(if|for|while|switch|try)\b|\b(if|for|while|switch|try)\s*\(")
SKIP_DIRS = {".dart_tool", "build", ".git", "node_modules"}
ROOTS = ("lib", "labs", "packages", "apps")


def logical_depth(path):
    stack = []
    best = 0
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.split("//")[0]
            stripped = line.strip()
            if not stripped:
                continue

            is_control = bool(CONTROL.match(stripped)) or bool(
                re.search(r"\b(if|for|while|switch)\s*\(", stripped)
            )
            if is_control:
                best = max(best, sum(stack) + 1)

            first = True
            for char in line:
                if char == "{":
                    stack.append(1 if (first and is_control) else 0)
                    first = False
                elif char == "}" and stack:
                    stack.pop()

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

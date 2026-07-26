"""Small prime-checking demo used to exercise the Orca review loop."""

from __future__ import annotations

import math
import sys


def is_prime(number: int) -> bool:
    """Return True when *number* is a prime integer."""
    if number < 2:
        return False
    if number == 2:
        return True
    if number % 2 == 0:
        return False
    for divisor in range(3, math.isqrt(number) + 1, 2):
        if number % divisor == 0:
            return False
    return True


def main(argv: list[str] | None = None) -> int:
    """Print a human-readable result for one integer argument."""
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 1:
        print("Usage: python prime_checker.py <integer>")
        return 2

    try:
        number = int(args[0])
    except ValueError:
        print(f"Input: {args[0]}")
        print("Result: invalid integer")
        return 2

    label = "PRIME" if is_prime(number) else "NOT PRIME"
    print(f"Input : {number}")
    print(f"Result: {label}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""Focused behavior checks for the prime-checking Orca demo."""

from prime_checker import is_prime, main


def test_prime_boundaries() -> None:
    assert not is_prime(-7)
    assert not is_prime(0)
    assert not is_prime(1)
    assert is_prime(2)
    assert is_prime(3)


def test_composites() -> None:
    assert not is_prime(4)
    assert not is_prime(9)
    assert not is_prime(100)


def test_cli_output(capsys) -> None:
    assert main(["13"]) == 0
    assert capsys.readouterr().out == "Input : 13\nResult: PRIME\n"


def test_cli_rejects_invalid_input(capsys) -> None:
    assert main(["not-a-number"]) == 2
    assert "invalid integer" in capsys.readouterr().out


if __name__ == "__main__":
    test_prime_boundaries()
    test_composites()
    print("prime behavior checks: PASS")

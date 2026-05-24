"""Business logic module."""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


class CoreError(Exception):
    """Base exception for core business logic errors."""

    pass


def compute_stats(values: list[float]) -> dict[str, float]:
    """
    Compute summary statistics for a list of numeric values.

    Args:
        values: List of numbers to analyze.

    Returns:
        Dictionary with keys: mean, min, max, count.

    Raises:
        CoreError: If values is empty or contains non-finite numbers.
    """
    if not values:
        raise CoreError("Cannot compute stats on empty list")

    finite = [v for v in values if __is_finite(v)]
    if len(finite) != len(values):
        raise CoreError("All values must be finite numbers")

    count = float(len(values))
    total = sum(values)
    return {
        "mean": total / count,
        "min": min(values),
        "max": max(values),
        "count": count,
    }


def __is_finite(x: float) -> bool:
    """Return True if x is finite (not inf or nan)."""
    try:
        return abs(x) != float("inf") and x == x  # nan != nan
    except (TypeError, ValueError):
        return False

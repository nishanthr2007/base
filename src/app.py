"""Application entry for default (no-args) run mode."""

from __future__ import annotations

import logging
import os
from pathlib import Path

log = logging.getLogger(__name__)


def run() -> None:
    """Run the default application logic."""
    env = os.environ.get("ENVIRONMENT", "dev")
    log_level = os.environ.get("LOG_LEVEL", "INFO")
    app_name = os.environ.get("APP_NAME", "base")
    log.info("App started | name=%s | environment=%s | log_level=%s", app_name, env, log_level)
    log.info("Logs directory: %s", Path(__file__).resolve().parent.parent / "logs")

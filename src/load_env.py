"""Load environment variables from env/ based on ENVIRONMENT."""

from __future__ import annotations

import logging
import os
from pathlib import Path

from dotenv import load_dotenv

log = logging.getLogger(__name__)

_ENV_LOADED = False


def load_env() -> None:
    """Load .env file from env/ based on ENVIRONMENT (dev, qa, prod). Default: dev."""
    global _ENV_LOADED
    if _ENV_LOADED:
        return
    env_name = os.environ.get("ENVIRONMENT", "dev")
    env_dir = Path(__file__).resolve().parent.parent / "env"
    env_file = env_dir / f".env.{env_name}"
    if env_file.exists():
        load_dotenv(env_file)
        log.debug("Loaded env from %s", env_file)
    else:
        log.warning("Env file not found: %s", env_file)
    _ENV_LOADED = True

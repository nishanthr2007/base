"""Application entry point."""

from __future__ import annotations

import argparse
import logging
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

from core import CoreError, compute_stats

LOG_FORMAT = "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
DEV_SERVE_ENV = "APP_DEV_SERVE"


def setup_logging(level: int = logging.INFO, log_dir: Path | None = None) -> None:
    """Configure root logger (stdout + optional logs/ file)."""
    handlers: list[logging.Handler] = [
        logging.StreamHandler(sys.stdout),
    ]
    if log_dir is not None:
        log_dir.mkdir(parents=True, exist_ok=True)
        log_file = log_dir / "app.log"
        handlers.append(logging.FileHandler(log_file, encoding="utf-8"))

    logging.basicConfig(
        level=level,
        format=LOG_FORMAT,
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=handlers,
        force=True,
    )


def parse_numbers(raw: list[str]) -> list[float]:
    """Parse CLI arguments into list of floats."""
    result: list[float] = []
    for s in raw:
        try:
            result.append(float(s))
        except ValueError as e:
            raise ValueError(f"Invalid number: {s!r}") from e
    return result


def run_app_mode() -> int:
    """Run the default application. Returns exit code."""
    from app import run as app_run
    from load_env import load_env

    load_env()
    app_run()
    return 0


def run_watch_mode(args: argparse.Namespace) -> int:
    """Run development server: watch files and auto-restart on change."""
    try:
        from watchdog.events import FileSystemEventHandler
        from watchdog.observers import Observer
    except ImportError:
        print(
            'Error: --watch requires watchdog. Install with: pip install -e ".[dev]"',
            file=sys.stderr,
        )
        return 1

    restart_event: threading.Event = threading.Event()
    changed_path: list[str] = []

    project_root = Path(__file__).resolve().parent.parent
    src_dir = project_root / "src"
    watch_dirs = [src_dir, project_root]
    watch_dirs = [d for d in watch_dirs if d.exists()]

    class RestartHandler(FileSystemEventHandler):
        def on_modified(self, event: object) -> None:
            if getattr(event, "is_directory", False):
                return
            src = getattr(event, "src_path", "")
            if src and (src.endswith(".py") or src.endswith(".pyc")):
                changed_path.append(src)
                restart_event.set()

    observer = Observer()
    for d in watch_dirs:
        observer.schedule(RestartHandler(), str(d), recursive=True)
    observer.start()

    log = logging.getLogger(__name__)
    log.info("Development server starting.")
    log.info("Watching for file changes. Ctrl+C to stop.")

    cmd = [sys.executable, "-m", "main", "--env", args.env]
    if args.verbose:
        cmd.append("-v")
    env = os.environ.copy()
    env[DEV_SERVE_ENV] = "1"
    if src_dir.exists():
        env["PYTHONPATH"] = str(src_dir) + (os.pathsep + env.get("PYTHONPATH", ""))

    proc: subprocess.Popen[bytes] | None = None
    exit_code = 0
    try:
        while True:
            restart_event.clear()
            changed_path.clear()
            proc = subprocess.Popen(cmd, cwd=str(src_dir), env=env)
            while not restart_event.is_set() and proc.poll() is None:
                time.sleep(0.25)
            if restart_event.is_set():
                if proc is not None:
                    proc.terminate()
                    try:
                        proc.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        proc.kill()
                        proc.wait()
                file_msg = changed_path[0] if changed_path else "file"
                log.info("File changed: %s", file_msg)
                log.info("Reloading application.")
            else:
                exit_code = proc.returncode if proc is not None else 0
                break
    except KeyboardInterrupt:
        log.info("Stopping development server.")
        if proc is not None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
            exit_code = 0
    finally:
        observer.stop()
        observer.join(timeout=2)
    return exit_code


def main() -> int:
    """Run the application. Returns exit code (0 = success)."""
    parser = argparse.ArgumentParser(
        description="Run the application or compute stats. Use --watch for development server."
    )
    parser.add_argument(
        "numbers",
        nargs="*",
        metavar="N",
        help="Optional numbers for stats (mean, min, max)",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable debug logging",
    )
    parser.add_argument(
        "--watch",
        action="store_true",
        help="Run development server: watch files and auto-restart on change (requires watchdog)",
    )
    parser.add_argument(
        "--env",
        choices=["dev", "qa", "prod"],
        default="dev",
        help="Environment to use (loads env/.env.<env>). Default: dev",
    )
    args = parser.parse_args()

    os.environ["ENVIRONMENT"] = args.env

    project_root = Path(__file__).resolve().parent.parent
    log_dir = project_root / "logs"
    level = logging.DEBUG if args.verbose else logging.INFO
    setup_logging(level, log_dir=log_dir)
    log = logging.getLogger(__name__)
    log.info("Application starting.")

    if args.watch:
        return run_watch_mode(args)

    if args.numbers:
        try:
            values = parse_numbers(args.numbers)
            log.debug("Parsed %d value(s)", len(values))
            stats = compute_stats(values)
            log.info(
                "count=%.0f mean=%.2f min=%.2f max=%.2f",
                stats["count"],
                stats["mean"],
                stats["min"],
                stats["max"],
            )
            print(
                f"count={stats['count']:.0f} mean={stats['mean']:.2f} "
                f"min={stats['min']:.2f} max={stats['max']:.2f}"
            )
            return 0
        except (ValueError, CoreError) as e:
            log.error("%s", e)
            print(f"Error: {e}", file=sys.stderr)
            return 1
        except Exception as e:
            log.exception("Unexpected error: %s", e)
            print(f"Unexpected error: {e}", file=sys.stderr)
            return 1

    try:
        code = run_app_mode()
        if os.environ.get(DEV_SERVE_ENV) == "1":
            log.info("Development server running. Press Ctrl+C to stop.")
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                pass
        return code
    except Exception as e:
        log.exception("Unexpected error: %s", e)
        print(f"Unexpected error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())


import logging
from pathlib import Path
from logging.handlers import RotatingFileHandler


# Backend directory
BASE_DIR = Path(__file__).resolve().parent

# Log directory
LOG_DIR = BASE_DIR / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

# Log file path
LOG_FILE = LOG_DIR / "scamshield_backend.log"


# Create logger
logger = logging.getLogger("scamshield")

logger.setLevel(logging.INFO)

# Prevent duplicate log handlers
logger.propagate = False


if not logger.handlers:

    # Log message format
    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )

    # Console logging
    console_handler = logging.StreamHandler()

    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)

    # File logging with automatic rotation
    file_handler = RotatingFileHandler(
        LOG_FILE,
        maxBytes=5 * 1024 * 1024,
        backupCount=5,
        encoding="utf-8"
    )

    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(formatter)

    # Register handlers
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)

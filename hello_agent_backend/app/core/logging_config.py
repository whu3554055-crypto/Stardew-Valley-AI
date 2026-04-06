"""
Structured Logging Configuration for Hello-Agent Backend

Provides JSON-formatted, leveled logging with context enrichment.
Integrates structlog for structured logs and Python logging for compatibility.
"""

import sys
import json
import logging
import traceback
from datetime import datetime, timezone
from typing import Any, Dict, Optional
from pathlib import Path

import structlog
from structlog.types import Processor


# ============================================================================
# Configuration
# ============================================================================

class LoggingConfig:
    """Logging configuration settings"""

    # Log levels
    LEVELS = {
        "DEBUG": logging.DEBUG,
        "INFO": logging.INFO,
        "WARNING": logging.WARNING,
        "ERROR": logging.ERROR,
        "CRITICAL": logging.CRITICAL
    }

    # Default log format for non-JSON handlers
    DEFAULT_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    # JSON log format keys
    JSON_KEYS = [
        "timestamp",
        "level",
        "event",
        "logger",
        "module",
        "function",
        "line",
        "message",
        "exception",
        "traceback",
        "request_id",
        "user_id",
        "session_id",
        "duration_ms"
    ]

    # Log file rotation settings
    MAX_BYTES = 10 * 1024 * 1024  # 10 MB
    BACKUP_COUNT = 5

    # Excluded loggers (too verbose)
    EXCLUDED_LOGGERS = [
        "uvicorn.access",
        "starlette.middleware.cors",
        "aiosqlite"
    ]


# ============================================================================
# Custom Processors
# ============================================================================

def add_timestamp(logger: Any, method_name: str, event_dict: Dict[str, Any]) -> Dict[str, Any]:
    """Add ISO 8601 timestamp to log events"""
    event_dict["timestamp"] = datetime.now(timezone.utc).isoformat()
    return event_dict


def add_log_level(logger: Any, method_name: str, event_dict: Dict[str, Any]) -> Dict[str, Any]:
    """Add uppercase log level to event dict"""
    event_dict["level"] = method_name.upper()
    return event_dict


def add_context_vars(logger: Any, method_name: str, event_dict: Dict[str, Any]) -> Dict[str, Any]:
    """Add common context variables if present"""
    # These can be set via structlog.contextvars.bind_contextvars()
    from structlog.contextvars import _CONTEXT_VARS

    context = _CONTEXT_VARS.get()
    if context:
        event_dict.update(context)

    return event_dict


def format_exception(logger: Any, method_name: str, event_dict: Dict[str, Any]) -> Dict[str, Any]:
    """Format exception information if present"""
    exc_info = event_dict.pop("exc_info", None)

    if exc_info is True:
        exc_info = sys.exc_info()

    if exc_info and exc_info[0] is not None:
        exception_type = exc_info[0].__name__
        exception_msg = str(exc_info[1])
        tb_lines = traceback.format_exception(*exc_info)

        event_dict["exception"] = {
            "type": exception_type,
            "message": exception_msg,
            "traceback": "".join(tb_lines)
        }

    return event_dict


def rename_event_to_message(logger: Any, method_name: str, event_dict: Dict[str, Any]) -> Dict[str, Any]:
    """Rename 'event' key to 'message' for consistency"""
    if "event" in event_dict:
        event_dict["message"] = event_dict.pop("event")
    return event_dict


def filter_excluded_loggers(logger: Any, method_name: str, event_dict: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Filter out logs from excluded loggers"""
    logger_name = event_dict.get("logger", "")

    for excluded in LoggingConfig.EXCLUDED_LOGGERS:
        if logger_name.startswith(excluded):
            return None

    return event_dict


# ============================================================================
# Formatters
# ============================================================================

class JSONFormatter(logging.Formatter):
    """Custom JSON formatter for Python logging"""

    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": datetime.fromtimestamp(record.created, tz=timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "message": record.getMessage()
        }

        # Add exception info if present
        if record.exc_info and record.exc_info[0] is not None:
            log_data["exception"] = {
                "type": record.exc_info[0].__name__,
                "message": str(record.exc_info[1]),
                "traceback": self.formatException(record.exc_info)
            }

        # Add extra fields
        if hasattr(record, "request_id"):
            log_data["request_id"] = record.request_id
        if hasattr(record, "user_id"):
            log_data["user_id"] = record.user_id

        return json.dumps(log_data, ensure_ascii=False, default=str)


class ColoredConsoleFormatter(logging.Formatter):
    """Colored console formatter for better readability"""

    COLORS = {
        "DEBUG": "\033[36m",     # Cyan
        "INFO": "\033[32m",      # Green
        "WARNING": "\033[33m",   # Yellow
        "ERROR": "\033[31m",     # Red
        "CRITICAL": "\033[1;31m" # Bold Red
    }
    RESET = "\033[0m"

    def format(self, record: logging.LogRecord) -> str:
        color = self.COLORS.get(record.levelname, self.RESET)

        log_parts = [
            f"{color}{record.levelname}{self.RESET}",
            f"{datetime.fromtimestamp(record.created).strftime('%H:%M:%S')}",
            f"{record.name}",
            f"{record.getMessage()}"
        ]

        if record.exc_info:
            log_parts.append(f"\n{self.formatException(record.exc_info)}")

        return " | ".join(log_parts)


# ============================================================================
# Setup Functions
# ============================================================================

def setup_structlog(
    log_level: str = "INFO",
    log_file: Optional[str] = None,
    json_logs: bool = True
):
    """
    Configure structlog with processors and handlers

    Args:
        log_level: Minimum log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        log_file: Optional log file path
        json_logs: Whether to use JSON formatting
    """

    # Configure standard library logging
    level = LoggingConfig.LEVELS.get(log_level.upper(), logging.INFO)

    # Root logger configuration
    root_logger = logging.getLogger()
    root_logger.setLevel(level)

    # Remove existing handlers
    root_logger.handlers.clear()

    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)

    if json_logs:
        console_handler.setFormatter(JSONFormatter())
    else:
        console_handler.setFormatter(ColoredConsoleFormatter())

    root_logger.addHandler(console_handler)

    # File handler (if specified)
    if log_file:
        log_path = Path(log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)

        from logging.handlers import RotatingFileHandler
        file_handler = RotatingFileHandler(
            log_file,
            maxBytes=LoggingConfig.MAX_BYTES,
            backupCount=LoggingConfig.BACKUP_COUNT
        )
        file_handler.setLevel(level)
        file_handler.setFormatter(JSONFormatter())
        root_logger.addHandler(file_handler)

    # Configure structlog processors
    processors = [
        # Filter excluded loggers
        filter_excluded_loggers,

        # Add context variables
        structlog.contextvars.merge_contextvars,

        # Add timestamp and level
        add_timestamp,
        add_log_level,

        # Handle exceptions
        format_exception,

        # Add caller information
        structlog.processors.CallerRenderer(skip_frames=1),

        # Rename event to message
        rename_event_to_message,

        # Output renderer
        structlog.processors.JSONRenderer() if json_logs else structlog.dev.ConsoleRenderer()
    ]

    structlog.configure(
        processors=processors,
        wrapper_class=structlog.make_filtering_bound_logger(level),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(),
        cache_logger_on_first_use=True
    )


def get_logger(name: Optional[str] = None):
    """
    Get a structured logger instance

    Usage:
        logger = get_logger(__name__)
        logger.info("User logged in", user_id="123", session_id="abc")
    """
    if name:
        return structlog.get_logger(name)
    return structlog.get_logger()


def bind_context(**kwargs):
    """
    Bind context variables to current execution context

    Usage:
        bind_context(user_id="123", request_id="abc")
        logger.info("Processing request")  # Will include user_id and request_id
    """
    structlog.contextvars.bind_contextvars(**kwargs)


def clear_context():
    """Clear all bound context variables"""
    structlog.contextvars.clear_contextvars()


# ============================================================================
# Logging Middleware for FastAPI
# ============================================================================

class RequestLoggingMiddleware:
    """Middleware to add request context to logs"""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        # Extract request info
        method = scope.get("method", "UNKNOWN")
        path = scope.get("path", "/")

        # Generate request ID
        import uuid
        request_id = str(uuid.uuid4())[:8]

        # Bind to logging context
        bind_context(request_id=request_id, method=method, path=path)

        logger = get_logger("http.request")
        logger.info(f"Request started: {method} {path}")

        # Track response
        async def wrapped_send(message):
            if message["type"] == "http.response.start":
                status_code = message.get("status", 0)
                bind_context(status_code=status_code)
                logger.info(f"Request completed: {method} {path} [{status_code}]")

            await send(message)

        try:
            await self.app(scope, receive, wrapped_send)
        except Exception as e:
            logger.error(f"Request failed: {method} {path}", exc_info=e)
            raise
        finally:
            clear_context()


# ============================================================================
# Initialize on Import
# ============================================================================

# Auto-configure with defaults (can be overridden by calling setup_structlog())
setup_structlog()

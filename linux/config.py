"""Configuration loader for KeyboardDrop."""
import json
import os
import sys
from pathlib import Path


def get_config_path() -> Path:
    """Get the config file path.

    Linux: ~/.config/keyboarddrop/config.json
    """
    if sys.platform.startswith("linux"):
        base = os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
        return Path(base) / "keyboarddrop" / "config.json"
    else:
        return Path.home() / ".config" / "keyboarddrop" / "config.json"


def load_config() -> dict:
    """Load and return the configuration dictionary.

    Returns default config if file doesn't exist.
    """
    config_path = get_config_path()
    default_config = {
        "mappings": {},
    }

    if not config_path.exists():
        return default_config

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
        # Ensure mappings key exists
        if "mappings" not in config:
            config["mappings"] = {}
        return config
    except (json.JSONDecodeError, OSError) as e:
        print(f"Warning: Failed to load config from {config_path}: {e}", file=sys.stderr)
        return default_config


def get_mappings(config: dict) -> dict:
    """Extract key mappings from config.

    Returns a dict mapping source key names to target key names.
    """
    return config.get("mappings", {})

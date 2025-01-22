from pathlib import Path
from os import getenv

BASE_DIR = Path(__file__).parent.parent.parent
META_DEFAULTS_FILE = BASE_DIR/'docker/files/meta.json'

CONFIG_REPO = Path(getenv('CONFIG_REPO', '/etc/postfix/repo'))
FORCE = bool(getenv('FORCE'))
FORCE_FILES = bool(getenv('FORCE_FILES', FORCE))
FORCE_CONFIG = bool(getenv('FORCE_CONFIG', FORCE))
FORCE_MAPS = bool(getenv('FORCE_MAPS', FORCE))
POSTMAP_BIN = Path(getenv('POSTMAP_BIN', '/usr/sbin/postmap'))

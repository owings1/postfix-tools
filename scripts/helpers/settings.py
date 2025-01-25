from os import getenv
from pathlib import Path

import dotenv

if Path('/etc/postfix/environment').exists():
    dotenv.load_dotenv('/etc/postfix/environment')

BASE_DIR = Path(__file__).parent.parent.parent

CONFIG_REPO = Path(getenv('CONFIG_REPO', '/opt/config'))
FORCE = bool(getenv('FORCE'))
FORCE_FILES = bool(getenv('FORCE_FILES', FORCE))
FORCE_CONFIG = bool(getenv('FORCE_CONFIG', FORCE))
FORCE_MAPS = bool(getenv('FORCE_MAPS', FORCE))
POSTMAP_BIN = Path(getenv('POSTMAP_BIN', '/usr/sbin/postmap'))
POSTCONF_BIN = Path(getenv('POSTCONF_BIN', '/usr/sbin/postconf'))

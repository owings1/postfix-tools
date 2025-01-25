from __future__ import annotations

import hashlib
import json
import subprocess
from enum import Enum
from pathlib import Path
from typing import Any

import settings


class AppMeta:

    defaults = {
        "pmapfiles": [
            "client_checks",
            "sender_checks",
            "local_dsn_filter",
            "virtual"
        ],
        "ignorekeys": [
            "maillog_file"
        ]
    }

    def __init__(self):
        metafile = settings.CONFIG_REPO/'meta.json'
        data = dict(self.defaults)
        if metafile.exists():
            data.update(_read_json(metafile))
        self.pmapfiles: list[str] = data['pmapfiles']
        self.ignorekeys = set(data['ignorekeys'])
        self.ignorekeys.add('config_directory')

class Clrs(str, Enum):
    reset = '\x1b[0m'
    red = '\x1b[0;31m'
    green = '\x1b[0;32m'
    blue = '\x1b[0;34m'
    magenta = '\x1b[0;35m'
    cyan = '\x1b[0;36m'
    cyanLight = '\x1b[1;36m'
    greyLight = '\x1b[0;37m'
    grey = '\x1b[1;30m'
    redLight = '\x1b[1;31m'
    greenLight = '\x1b[1;32m'
    yellow = '\x1b[0;33m'
    yellowLight = '\x1b[1;33m'
    blueLight = '\x1b[1;34m'
    magentaLight = '\x1b[1;35m'
    white = '\x1b[1;37m'
    whiteLight = '\x1b[37;1m'
    dim = '\x1b[2m'
    undim = '\x1b[22m'

    def __str__(self):
        return self.value

    def wrap(self, text: str) -> str:
        return f'{self}{text}{self.reset}'

    __call__ = wrap


def _read_json(file: Path) -> dict[str, Any]:
    with file.open() as f:
        return json.load(f)

def postconf(*args) -> str:
    cmd = [settings.POSTCONF_BIN, *args]
    proc = subprocess.run(cmd, capture_output=True, check=True, text=True)
    return proc.stdout.strip()

def md5file(file: Path) -> str:
    return hashlib.md5(file.read_bytes()).hexdigest()

meta = AppMeta()

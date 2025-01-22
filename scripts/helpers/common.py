from __future__ import annotations

import hashlib
import json
from enum import Enum
from pathlib import Path
from typing import Any

import settings


class AppMeta(object):
    def __init__(self):
        self.defaults = _read_json(settings.META_DEFAULTS_FILE)
        self.srcdir = settings.CONFIG_REPO
        self.filesdir = self.srcdir/'files'
        metafile = self.srcdir/'meta.json'
        data = dict(self.defaults)
        if metafile.exists():
            usermeta = _read_json(metafile)
            data.update(usermeta)
            data['auth'] = dict(self.defaults['auth'])
            data['auth'].update(usermeta.get('auth', {}))
        self.pmapfiles: list[str] = data['pmapfiles']
        self.ignorekeys = set(data['ignorekeys'])
        self.ignorekeys.add('config_directory')
        self.force = settings.FORCE
        self.forcefiles = settings.FORCE_FILES
        self.forceconfig = settings.FORCE_CONFIG
        self.forcemaps = settings.FORCE_MAPS
        self.auth = data['auth']
        self.data = data

def _read_json(file: Path) -> dict[str, Any]:
    with file.open() as f:
        return json.load(f)

meta = AppMeta()


def md5file(file: Path) -> str:
    return hashlib.md5(file.read_bytes()).hexdigest()

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

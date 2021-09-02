import hashlib
import json
import os
import os.path
import pathlib
import shlex
import shutil
import subprocess
import sys

exists = os.path.exists
pabs = os.path.abspath
pjoin = os.path.join

def rdjson(file):
    with open(file) as reader:
        return json.load(reader)
def envbool(key):
    return key in os.environ and bool(os.environ[key])

class AppMeta(object):
    def __init__(self):
        self.srcdir = pabs(os.environ['USER_SOURCE'])
        metafile = pjoin(self.srcdir, 'meta.json')
        data = rdjson(metafile)
        self.hashfiles = data['hashfiles']
        self.ignorekeys = set(data['ignorekeys'])
        self.ignorekeys.add('config_directory')
        self.filesdir = pjoin(self.srcdir, 'files')
        self.force = envbool('FORCE')
        self.forcefiles = self.force or envbool('FORCE_FILES')
        self.forceconfig = self.force or envbool('FORCE_CONFIG')
        self.forcemaps = self.force or envbool('FORCE_MAPS')

meta = AppMeta()

class Bins(object):
    def __init__(self):
        self.postmap = '/usr/sbin/postmap'

bins = Bins()

def exc(args, check=True, **kw):
    return subprocess.run(args, check=check, **kw)

def mapdbfile(src):
    return pjoin(os.path.dirname(src), '.'.join([os.path.basename(src), 'db']))

def modstat(file):
    stat = pathlib.Path(file).stat()
    md5 = md5file(file)
    return (stat.st_size, stat.st_mtime, md5)

def modstats(*files):
    return tuple(modstat(file) for file in files)

def modhash(*files):
    return str(modstats(*files))

def md5file(file):
    return hashlib.md5(open(file,'rb').read()).hexdigest()

def qline(line, is_last = False):
    end = '' if is_last else ' \\'
    return ''.join(('    ', shlex.quote(line), end))

def wrfile(file, *lines):
    content = '\n'.join(lines)
    with open(file, 'w') as writer:
        writer.write(content)

def wrjson(file, data):
    with open(file, 'w') as writer:
        json.dump(data, writer, indent=2)


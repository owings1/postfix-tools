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
pbname = os.path.basename

def rdjson(file):
    with open(file) as reader:
        return json.load(reader)
def envbool(key):
    return key in os.environ and bool(os.environ[key])



class AppMeta(object):
    def __init__(self):
        defaultfile = pjoin(os.path.dirname(pabs(__file__)), '../docker/files/meta.json')
        defaults = self.defaults = rdjson(defaultfile)
        if 'CONFIG_REPO' in os.environ:
            self.srcdir = os.environ['CONFIG_REPO']
        else:
            self.srcdir = '/etc/postfix/repo'
        self.filesdir = pjoin(self.srcdir, 'files')
        metafile = pjoin(self.srcdir, 'meta.json')
        if exists(metafile):
            data = rdjson(metafile)
        else:
            data = defaults
        def getval(key):
            return data[key] if key in data else defaults[key]

        self.hashfiles = getval('hashfiles')
        self.ignorekeys = set(getval('ignorekeys'))
        self.ignorekeys.add('config_directory')
        
        self.force = envbool('FORCE')
        self.forcefiles = self.force or envbool('FORCE_FILES')
        self.forceconfig = self.force or envbool('FORCE_CONFIG')
        self.forcemaps = self.force or envbool('FORCE_MAPS')
        self.auth = getval('auth')
        for key in defaults['auth']:
            if key not in self.auth:
                self.auth[key] = defaults['auth'][key]
        self.data = data

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

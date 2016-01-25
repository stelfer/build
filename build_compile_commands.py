#!/usr/bin/env python
#
# Copyright (C) 2016 by AT&T Services Inc. - MIT License. See LICENSE.txt
#
# So, the strategy here is to load all of the values from sys.argv[1], then check all of
# sys.argv[1:] and only insert if there is a difference. Then, if there is, then we atomically
# rename with os.rename
#
import sys
import json
import itertools
import tempfile
import os
import fcntl
import time
import errno

assert len(sys.argv) > 2

def process(file):
    try:
        values = json.load(file)
        keys = [x['file'] for x in values]            
    except:
        values = []
        keys = []

    out = dict(itertools.izip(keys, values))
    nchanged = False
    for f in sys.argv[2:]:
        with open(f) as file:
            for i in json.load(file):
                key = i['file']
                if key in out and out[key] == i:
                    pass
                else:
                    out[key] = i
                    nchanged = True

    if nchanged:
        if not os.path.exists("build/tmp"):
            os.mkdir("build/tmp")
        with tempfile.NamedTemporaryFile(dir="build/tmp") as tmp:
            json.dump(out.values(), tmp, indent=4)
            try:
                os.rename(tmp.name, sys.argv[1])
                tmp.delete = False
            except:
                pass
    
        
if __name__ == '__main__':
    flags = os.O_CREAT | os.O_RDONLY
    try:
        fd = os.open(sys.argv[1], flags)
    except OSError as e:
        raise
    else:
        with os.fdopen(fd, "r") as file:
            cnt = 0
            while cnt < 100:
                cnt += 1
                try:
                    fcntl.flock(file, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    process(file)
                    fcntl.flock(file, fcntl.LOCK_UN)
                    sys.exit(0)
                except IOError as e:
                    # raise on unrelated IOErrors
                    if e.errno != errno.EAGAIN:
                        raise
                else:
                    print "SLEEPING!"
                    time.sleep(0.1)
    sys.exit(1)

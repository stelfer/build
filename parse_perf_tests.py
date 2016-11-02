#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

import sys
import os.path
import math

import build

class colors:
    RED = '\033[31m'
    RESET = '\033[0m'
    GREEN = '\033[32m'




# Start here
print colors.GREEN + "[==========] " + colors.RESET + "Checking perf tests"


curr = None
prev = None

try:
    curr = sys.argv[1]
    if not os.path.isfile(curr):
        curr = None
    prev = sys.argv[2]
    if not os.path.isfile(prev):
        prev = None
except:
    pass

if curr is None or prev is None:
    print colors.GREEN + "[       OK ] " + colors.RESET + "No previous results found"
    sys.exit(0)
    
curr_machine_id,curr_ts,curr = build.get_tree(curr)
prev_machine_id,prev_ts,prev = build.get_tree(prev)

if curr_machine_id != prev_machine_id:
    print colors.GREEN + "[       OK ] " + colors.RESET + "Results from different machines"
    sys.exit(0)
    
for classname in curr:
    for name in curr[classname]:
        if classname in prev and name in prev[classname]:
            c = curr[classname][name]
            p = prev[classname][name]
            fullname = classname + "." + name

            # r values can disagree by 1 part in 10^3
            if math.fabs(float(c['r']) - float(p['r']))*1000 > 1.0:
                reason = " Ratios differ (curr=%s, prev=%s)" % (c['r'], p['r'])
                print colors.RED + "[  FAILED  ] " + colors.RESET + fullname + reason
                print colors.RED + "[==========] " + colors.RESET + "Run make with RESET_PERF=1 to clear prev"
                sys.exit(1)
            else:
                ins = float(c['ins'])
                cyc = float(c['cyc'])
                N = float(c['N'])
                print colors.GREEN + "[       OK ] %-20s " %( fullname) + colors.RESET +\
                    ": ins=%.2f cyc=%.2f N=%s r=%s cpi=%s"  %(ins/N, cyc/N, c['N'], c['r'], c['cpi'])

print colors.GREEN + "[  PASSED  ] " + colors.RESET + str(len(curr)) + " perf tests."


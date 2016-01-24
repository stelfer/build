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
import xml.etree.ElementTree as ET
import os.path
import math

class colors:
    RED = '\033[31m'
    RESET = '\033[0m'
    GREEN = '\033[32m'


def get_tree(s):
    """ Go through the xml doc and extract the perf tests"""
    tree = ET.parse(s)
    root = tree.getroot()
    attrs = dict()
    for child in root.findall("testsuite/testcase[@perf-test='1']"):
        c = child.attrib
        cname = c['classname']
        if not cname in attrs:
            attrs[cname] = dict()
        attrs[cname][c['name']] = c
    return attrs


# Start here
print colors.GREEN + "[==========] " + colors.RESET + "Checking perf tests"

root = sys.argv[1]
curr = None
prev = None
if os.path.isfile(root + ".xml"):
    curr = root + ".xml"
    if os.path.isfile(root + ".pass.xml"):
        prev = root + ".pass.xml"

if curr is None or prev is None:
    print colors.GREEN + "[       OK ] " + colors.RESET + "No previous results found"
    sys.exit(0)
    
curr = get_tree(curr)
prev = get_tree(prev)

for classname in curr:
    for name in curr[classname]:
    
        if classname in prev and name in prev[classname]:
            c = curr[classname][name]
            p = prev[classname][name]
            
            fullname = classname + "." + name
            
            # Let number of instructions differ by 0.1%%
            cond1 = math.fabs(float(c['ins']) - float(p['ins']))/float(c['ins']) > 0.001

            # Number of test cycles must be the same
            cond2 = int(c['N']) != int(p['N'])
            
            # r values can disagree by 1 part in 10^6
            cond3 = math.fabs(float(c['r']) - float(p['r']))*1000 > 1.0

            if cond1 or cond2 or cond3:
                reason = " : "
                if cond1:
                    reason += " Instruction count differs (curr=%s, prev=%s)" % (c['ins'], p['ins'])
                if cond2:
                    reason += " Number of test cycles differs (curr=%s, prev=%s)" % (c['N'], p['N'])
                if cond3:
                    reason += " Ratios differ (curr=%s, prev=%s)" % (c['r'], p['r'])
                print colors.RED + "[  FAILED  ] " + colors.RESET + fullname + reason
                print colors.RED + "[==========] " + colors.RESET + "Run make with RESET_PERF=1 to clear prev"
                sys.exit(1)
            else:
                ins = float(c['ins'])
                cyc = float(c['cyc'])
                N = float(c['N'])
                print colors.GREEN + "[       OK ] " + colors.RESET + fullname + \
                    " : ins=%.2f cyc=%.2f N=%s r=%s cpi=%s"  %(ins/N, cyc/N, c['N'], c['r'], c['cpi'])

print colors.GREEN + "[  PASSED  ] " + colors.RESET + str(len(curr)) + " perf tests."


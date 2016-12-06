# Copyright (C) 2016 by telfer - MIT License. See LICENSE.txt

import xml.etree.ElementTree as ET
import sys
import os.path
from os.path import isfile
import math
from scipy import stats

class NBExtractor:
    """ This tries to automatically generate Jupyter notebooks from run data... Borked but here for future generations. """
    def add_cell(nb):
        cell = {
            "cell_type": "code",
            "execution_count": 6,
            "metadata": {
                "collapsed": False
            },
            "source" : [],
            "outputs" : []
        }
        nb["cells"].append(cell)
        return cell


    def __init__(self):

        nb = {
            "cells": [
                {
                    "cell_type": "code",
                    "execution_count": 6,
                    "metadata": {
                        "collapsed": False
                    },
                    "outputs": [],
                    "source": [
                        "%matplotlib inline\n",
                        "import numpy as np\n",
                        "import seaborn as sns\n",
                        "from numpy.random import randn\n",
                        "import pandas as pd\n",
                        "from scipy import stats\n",
                        "import matplotlib as mpl\n",
                        "import matplotlib.pyplot as plt\n",
                        "import math\n",
                        "sns.set_style(\"whitegrid\")"
                    ]
                }            
            ],
            "metadata": {
                "kernelspec": {
                    "display_name": "Python 2",
                    "language": "python",
                    "name": "python2"
                },
                "language_info": {
                    "codemirror_mode": {
                        "name": "ipython",
                        "version": 2
                    },
                    "file_extension": ".py",
                    "mimetype": "text/x-python",
                    "name": "python",
                    "nbconvert_exporter": "python",
                    "pygments_lexer": "ipython2",
                    "version": "2.7.12"
                }
            },
            "nbformat": 4,
            "nbformat_minor": 1
        }

        plots=[]
        i = 0
        for classname in curr:
            for name in curr[classname]:
                c = curr[classname][name]
                #        p = prev[classname][name]

                cur_name = c["name"]
                cur_data = c["data"]
                cell = add_cell(nb)
                cell["source"].append(
                    """%s=%s
%s_df = pd.DataFrame(%s, columns=['N', 'type', 'num_rounds', 'counts', 'val', 'disp', 'var', 'mean', 'rate']).set_index('N')
%s_cnt = %s_df[%s_df['type'] == 0]
""" % (cur_name, cur_data, cur_name, cur_name, cur_name, cur_name, cur_name))

                plots.append("%s_cnt" % cur_name)
        
                # cell["source"].append("%s_df['val'][%s_df['type'] == 0].plot(marker='o', ax=axes[%d], title='%s', xlim=0, ylim=0)\n" % (c["name"], c["name"], i, c["name"]))
                i += 1

        cell = add_cell(nb)
        for p in plots:
            cell["source"].append("(%s.val).plot(marker='o', xlim=5, ylim=0, logy=True, label='%s', legend=True)\n" % (p,p))
    
        import json
        with open('../../stuff/out.ipynb', 'w') as f:
            f.write(json.dumps(nb))
        

class ConsolePrinter():
    """ A simple color printer to match gtest output. """
    def __init__(self):
        self.RED = '\033[31m'
        self.RESET = '\033[0m'
        self.GREEN = '\033[32m'


    def output(self, color, bar, msg):
        print color + bar + self.RESET + msg
    
    def msg(self, msg):
        self.output(self.GREEN, "[==========] ", msg)

    def ok(self, msg):
        self.output(self.GREEN, "[       OK ] ", msg)


    def fail(self, msg):
        self.output(self.RED, "[     FAIL ] ", msg)
        

class TestChecker:
    """A Class to check the results of the test.

    Does a hypothesis test based on properties of the sums of the compute times. For more info look in
    doc.  Rejects if p < alpha more than fail percent times.
    """
    def __init__(self, alpha = 0.05, fail_percent = 0.10):

        self.alpha = alpha
        self.fail_percent = fail_percent
        self.printer = ConsolePrinter()
        self.printer.msg("Checking perf tests")
        
        self.curr = None
        self.prev = None

        try:
            if isfile(sys.argv[1]):
                self.curr = sys.argv[1]
            if isfile(sys.argv[2]):
                self.prev = sys.argv[2]
        except:
            pass


        if self.curr is None:
            self.printer.fail("Can't get results")
            sys.exit(0)

        if self.prev is None:
            self.printer.ok("No previous results found")
            sys.exit(0)

        self.analyze_tests()
        
    def analyze_tests(self):
        curr_machine_id, curr_cpu_info, curr_ts, curr = self.get_tree(self.curr)
        prev_machine_id, prev_cpu_info, prev_ts, prev = self.get_tree(self.prev)

        if curr_machine_id != prev_machine_id:
            self.printer.ok("Results from different machines, resetting.")
            sys.exit(0)
        
        num_tests = 0
        num_failed = 0
        for classname in curr:
            for name in curr[classname]:
                if classname in prev and name in prev[classname]:
                    num_tests += 1
                    c = curr[classname][name]
                    p = prev[classname][name]
                    fullname = classname + "." + name
                    p_data = eval(p['data'])
                    c_data = eval(c['data'])
                    p_values = []
                    for k,pv in p_data.iteritems():
                        psum, pl, pn = pv
                        csum, cl, cn = c_data[k]
                        U = (psum/pn)/(csum/cn)
                        p_value = 2 * stats.f.cdf(U, 2*pn, 2*cn)
                        p_values.append(p_value)

                    failures = [ int(p <= self.alpha) for p in p_values]

                    # Failure criterion #2: More than 10% failures
                    fail_val = sum(failures)
                    fail_cond = fail_val > int(math.ceil(self.fail_percent * len(p_data.keys())))

                    if fail_cond:
                        reason = " fail_val = %d(%d)" % (fail_val, fail_cond)
                        self.printer.fail("%-20s" % (fullname) + reason)
                        num_failed += 1
                    else:
                        result = "min(p) = %f, failures = %d" % (min(p_values), fail_val)
                        self.printer.ok("%-20s " %(fullname) + result)

        if num_failed == 0:
            self.printer.ok(str(num_tests) + " perf tests.")
        else:
            self.printer.fail("%d/%d failed." % (num_failed, num_tests))
            sys.exit(1)


    def get_tree(self, s):
        """ Go through the xml doc and extract the perf tests"""
        tree = ET.parse(s)
        root = tree.getroot()
        attrs = dict()
        ts = root.attrib["timestamp"]
        machine_id = root.attrib["machine-id"]
        cpu_info = root.attrib["cpu-info"]
        for child in root.findall("testsuite/testcase[@perf-test='1']"):
            c = child.attrib
            cname = c['classname']
            if not cname in attrs:
                attrs[cname] = dict()
            attrs[cname][c['name']] = c
        return machine_id,cpu_info,ts, attrs

        

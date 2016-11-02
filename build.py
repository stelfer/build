# Copyright (C) 2016 by telfer - MIT License. See LICENSE.txt

import xml.etree.ElementTree as ET

def get_tree(s):
    """ Go through the xml doc and extract the perf tests"""
    tree = ET.parse(s)
    root = tree.getroot()
    attrs = dict()
    ts = root.attrib["timestamp"]
    machine_id = root.attrib["machine-id"]
    for child in root.findall("testsuite/testcase[@perf-test='1']"):
        c = child.attrib
        cname = c['classname']
        if not cname in attrs:
            attrs[cname] = dict()
        attrs[cname][c['name']] = c
    return machine_id,ts, attrs

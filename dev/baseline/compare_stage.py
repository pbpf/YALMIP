#!/usr/bin/env python3
"""Compare stage XML results against baseline XMLs, per test case."""
import xml.etree.ElementTree as ET, glob, sys, os

def load(path, prefix=''):
    res = {}
    for f in glob.glob(path):
        name = os.path.basename(f)[:-4]
        if name.startswith(prefix) and not name.startswith('probe') and not name.startswith('stage'):
        # strip stage prefix
            pass
        t = ET.parse(f).getroot()
        suites = t.findall('testsuite') or [t]
        for ts in suites:
            for tc in ts.iter('testcase'):
                key = (ts.get('name',''), tc.get('name',''))
                status = 'pass'
                if tc.find('failure') is not None: status = 'fail'
                if tc.find('error') is not None: status = 'error'
                if tc.find('skipped') is not None: status = 'skip'
                res[key] = status
    return res

base = load('dev/baseline/*.xml')
stage = {}
for f in glob.glob('dev/baseline/stage*_*.xml'):
    t = ET.parse(f).getroot()
    suites = t.findall('testsuite') or [t]
    for ts in suites:
        for tc in ts.iter('testcase'):
            key = (ts.get('name',''), tc.get('name',''))
            status = 'pass'
            if tc.find('failure') is not None: status = 'fail'
            if tc.find('error') is not None: status = 'error'
            if tc.find('skipped') is not None: status = 'skip'
            stage[key] = status

newbad, fixed, stillbad = [], [], []
for k, st in stage.items():
    bs = base.get(k, 'absent')
    if st in ('fail','error') and bs not in ('fail','error'):
        newbad.append((k, bs, st))
    elif st in ('fail','error') and bs in ('fail','error'):
        stillbad.append(k)
    elif bs in ('fail','error') and st == 'pass':
        fixed.append(k)

print(f"tests in stage: {len(stage)}, in baseline: {len(base)}")
print(f"NEW failures/errors: {len(newbad)}")
for k, bs, st in newbad: print(f"  NEW BAD {st} (was {bs}): {k[0]}/{k[1]}")
print(f"fixed vs baseline: {len(fixed)}")
for k in fixed: print(f"  FIXED: {k[0]}/{k[1]}")
print(f"still failing (same as baseline): {len(stillbad)}")
for k in stillbad: print(f"  STILL: {k[0]}/{k[1]}")
missing = [k for k in base if k not in stage]
print(f"in baseline but not in stage run: {len(missing)}")
for k in missing[:20]: print(f"  MISSING: {k[0]}/{k[1]}")

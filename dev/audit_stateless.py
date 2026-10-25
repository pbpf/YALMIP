#!/usr/bin/env python3
"""Stage 3 acceptance audit: zero global/persistent/dispatcher calls outside dev.

Usage: python3 dev/audit_stateless.py [--fix-report-only]
Exits nonzero if any violation is found.
"""
import re, subprocess, sys, os

def os_path_exists(p):
    return os.path.exists(p)

def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout.strip()

ok = True

g = run("grep -rn '^\\s*global\\b' --include=*.m . | grep -v './dev/' || true")
if g:
    ok = False
    print("GLOBAL declarations remain:")
    print(g)

p = run("grep -rn '^\\s*persistent\\b' --include=*.m . | grep -v './dev/' || true")
if p:
    ok = False
    print("PERSISTENT declarations remain:")
    print(p)

y = run("grep -rn \"yalmip('\" --include=*.m . | grep -v './dev/' | grep -v \"^\\S*:\\s*%\" | grep -v \":\\s*%\" || true")
if y:
    ok = False
    print("yalmip(' dispatcher calls remain:")
    print(y)

if os_path_exists('/media/connor/Data/YALMIP/extras/yalmip.m'):
    ok = False
    print("extras/yalmip.m (dispatcher) still exists - delete it in the final cutover")

print("AUDIT", "PASSED" if ok else "FAILED")
sys.exit(0 if ok else 1)

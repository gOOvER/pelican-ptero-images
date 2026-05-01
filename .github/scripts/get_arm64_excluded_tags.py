#!/usr/bin/env python3
"""
Reads a GitHub Actions workflow YAML and prints all matrix tags
that are excluded for linux/arm64, one per line.
Usage: python3 get_arm64_excluded_tags.py <workflow.yml>
"""
import sys
import yaml

try:
    with open(sys.argv[1]) as f:
        data = yaml.safe_load(f)
    for job in data.get('jobs', {}).values():
        matrix = job.get('strategy', {}).get('matrix', {})
        for exc in matrix.get('exclude', []):
            if exc.get('platform') == 'linux/arm64':
                print(exc.get('tag'))
except Exception:
    pass

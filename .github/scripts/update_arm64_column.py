#!/usr/bin/env python3
"""
Updates the ARM64 status column for an image entry in README.md.
Usage: python3 update_arm64_column.py <readme.md> <image_name> <arm64_flag>
Example: python3 update_arm64_column.py README.md 'java:shenandoah_8' '❌'
"""
import sys
import re

readme, image, arm64 = sys.argv[1], sys.argv[2], sys.argv[3]

with open(readme, encoding='utf-8') as f:
    content = f.read()

pattern = (
    r'(\| '
    + re.escape(image)
    + r' \| `[^`]+` \| (?:\u2705|\u274c) \| )(?:\u2705|\u274c)( \|)'
)
new_content = re.sub(pattern, r'\g<1>' + arm64 + r'\g<2>', content)

if new_content != content:
    with open(readme, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f'  \U0001f504 {image} \u2192 ARM64: {arm64}')

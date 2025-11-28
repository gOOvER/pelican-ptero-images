import json
import re
import sys

# Load scanned images
with open('images.json', 'r') as f:
    images = json.load(f)

# Read current README
with open('README.md', 'r') as f:
    readme = f.read()

changes_made = []

def generate_table_rows(items, image_name, tag_prefix="", arm64_default="✅"):
    rows = []
    for item in items:
        if tag_prefix:
            tag = f"{tag_prefix}_{item}"
            display = f"{image_name}:{tag_prefix}_{item}"
        else:
            tag = item
            display = f"{image_name}:{item}"
        rows.append(f"| {display} | `ghcr.io/goover/{image_name}:{tag}` | ✅ | {arm64_default} |")
    return rows

def check_missing_images(readme, items, image_name, tag_prefix=""):
    missing = []
    for item in items:
        if tag_prefix:
            search_tag = f"{tag_prefix}_{item}"
        else:
            search_tag = str(item)

        # Check if this version exists in README
        pattern = f"{image_name}:{search_tag}"
        if pattern not in readme:
            missing.append(item)
    return missing

# Check all image categories for missing entries
missing_images = {}

# Java Base
if images.get('java_base'):
    missing = check_missing_images(readme, images['java_base'], 'java')
    if missing:
        missing_images['Java Base'] = missing

# Java GraalVM
if images.get('java_graalvm'):
    missing = check_missing_images(readme, images['java_graalvm'], 'java', 'graalvm')
    if missing:
        missing_images['Java GraalVM'] = missing

# Java Corretto
if images.get('java_corretto'):
    missing = check_missing_images(readme, images['java_corretto'], 'java', 'corretto')
    if missing:
        missing_images['Java Corretto'] = missing

# Java Zulu
if images.get('java_zulu'):
    missing = check_missing_images(readme, images['java_zulu'], 'java', 'zulu')
    if missing:
        missing_images['Java Zulu'] = missing

# Java Dragonwell
if images.get('java_dragonwell'):
    missing = check_missing_images(readme, images['java_dragonwell'], 'java', 'dragonwell')
    if missing:
        missing_images['Java Dragonwell'] = missing

# Java Liberica
if images.get('java_liberica'):
    missing = check_missing_images(readme, images['java_liberica'], 'java', 'liberica')
    if missing:
        missing_images['Java Liberica'] = missing

# Java Shenandoah
if images.get('java_shenandoah'):
    missing = check_missing_images(readme, images['java_shenandoah'], 'java', 'shenandoah')
    if missing:
        missing_images['Java Shenandoah'] = missing

# Databases
for db in ['mariadb', 'postgres', 'mongodb', 'redis']:
    if images.get(db):
        missing = check_missing_images(readme, images[db], db)
        if missing:
            missing_images[db.title()] = missing

# Dev images
for dev in ['nodejs', 'python', 'go', 'elixir']:
    if images.get(dev):
        missing = check_missing_images(readme, images[dev], dev)
        if missing:
            missing_images[dev.title()] = missing

# Games, Bots, Apps
if images.get('games'):
    missing = check_missing_images(readme, images['games'], 'games')
    if missing:
        missing_images['Games'] = missing

if images.get('bots'):
    missing = check_missing_images(readme, images['bots'], 'bots')
    if missing:
        missing_images['Bots'] = missing

if images.get('apps'):
    missing = check_missing_images(readme, images['apps'], 'apps')
    if missing:
        missing_images['Apps'] = missing

# Output results
if missing_images:
    print("MISSING_IMAGES=true")
    print("\n📝 Missing images detected:")
    for category, items in missing_images.items():
        print(f"  {category}: {', '.join(str(i) for i in items)}")

    # Save missing images for PR description
    with open('missing_images.txt', 'w') as f:
        for category, items in missing_images.items():
            f.write(f"- **{category}**: {', '.join(str(i) for i in items)}\n")
else:
    print("MISSING_IMAGES=false")
    print("✅ README is up to date!")


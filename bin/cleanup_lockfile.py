#!/usr/bin/env python3
import re
import sys
from pathlib import Path

import yaml


def cleanup_lockfile(path: Path):
    with path.open() as f:
        data = yaml.safe_load(f)

    cleaned_deps = []
    for dep in data.get("dependencies", []):
        if isinstance(dep, str):
            if not re.match(r"^urllib3=2", dep):
                cleaned_deps.append(dep)
        elif isinstance(dep, dict) and "pip" in dep:
            pip_deps = dep["pip"]
            cleaned_pip = [pkg for pkg in pip_deps if not re.match(r"^urllib3==2", pkg)]
            cleaned_deps.append({"pip": cleaned_pip})

    data["dependencies"] = cleaned_deps

    # Write back without the 'prefix' key
    prefix = data.pop("prefix", None)

    with path.open("w") as f:
        yaml.dump(data, f, sort_keys=False)

        # Add prefix back as a commented line (if it existed)
        if prefix:
            f.write(f"# prefix: {prefix}\n")

    print(f"✅ Cleaned {path.name}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: cleanup_lockfile.py <lockfile.yml>")
        sys.exit(1)

    lockfile = Path(sys.argv[1])
    if not lockfile.exists():
        print(f"❌ File not found: {lockfile}")
        sys.exit(1)

    cleanup_lockfile(lockfile)

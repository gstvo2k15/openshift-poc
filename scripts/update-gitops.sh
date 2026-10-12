#!/usr/bin/env bash
set -euo pipefail
: "${IMAGE:?Set IMAGE to the published image reference, preferably @sha256 digest}"
python3 - "$IMAGE" <<'PYCODE'
from pathlib import Path
import sys
p=Path('gitops/base/deployment.yaml')
s=p.read_text()
import re
s,n=re.subn(r'(?m)^(\s*image:)\s+\S+',lambda m:m.group(1)+' '+sys.argv[1],s,count=1)
if n != 1: raise SystemExit('Image line not found')
p.write_text(s)
PYCODE
printf 'Updated image to %s; commit and push to trigger Argo CD.
' "$IMAGE"

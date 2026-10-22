"""Verify bundled review assets, or restore missing files with --download.
No paid or excluded Bestiary assets are fetched. Run from any directory.
"""
import argparse, hashlib, json, urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MANIFEST=json.loads((ROOT/'art_lab/SOURCES.json').read_text())
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--download',action='store_true',help='Restore missing files from pinned public URLs')
args=parser.parse_args()
for entry in MANIFEST['downloads']:
    path=ROOT/entry['path']
    expected=entry.get('installed_sha256',entry['sha256'])
    if path.exists():
        if hashlib.sha256(path.read_bytes()).hexdigest()!=expected:
            raise SystemExit('Hash mismatch; preserving file: '+entry['path'])
        continue
    if not args.download:raise SystemExit('Missing: '+entry['path']+' (use --download to restore)')
    request=urllib.request.Request(entry['url'],headers={'User-Agent':'VerdantOathArtLab/1.0'})
    data=urllib.request.urlopen(request,timeout=45).read()
    if hashlib.sha256(data).hexdigest()!=entry['sha256']:
        raise SystemExit('Download hash mismatch; file not written: '+entry['path'])
    if entry.get('installed_sha256') and entry['installed_sha256']!=entry['sha256']:
        text=data.decode().replace('typeof(gstate.get_additional_data(&"vrm/already_processed")) != TYPE_NIL','gstate.has_meta(&"vrm_already_processed")').replace('gstate.set_additional_data(&"vrm/already_processed", true)','gstate.set_meta(&"vrm_already_processed", true)')
        data=text.encode()
        if hashlib.sha256(data).hexdigest()!=expected:raise SystemExit('Patch hash mismatch: '+entry['path'])
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_bytes(data)
print('Verified all pinned review asset/addon hashes.')

from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[1]
source=root/'floating_glass_frlg'
def verify():
    records=json.loads((root/'ARQUIVOS.json').read_text())
    expected={e['path']:e['sha256'] for e in records}
    actual={p.relative_to(source).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in source.rglob('*') if p.is_file()}
    assert actual==expected,'Payload differs from ARQUIVOS.json'
    manifest=json.loads((source/'manifest.json').read_text())
    assert manifest['id']=='floating_glass_frlg' and manifest['game_version']=='>=0.3.93' and manifest['api']==2
    assert not manifest['dependencies']
    assert manifest['version'] in (source/'gen3/bootstrap.lua').read_text()
    for name in ['journal','journal_draw','journal_views','menus','options','surface']:
        assert not (source/'gen3'/f'{name}.lua').exists(),'Inactive KRS menu in payload'
    assert not (source/'assets/journal').exists(),'Inactive menu assets in payload'
    for e in json.loads((root/'REMOVIDOS.json').read_text()):
        path=Path(e['path']);assert not path.is_absolute() and '..' not in path.parts
        assert e['hashes'] and not (source/path).exists()
    print(f"{len(actual)} payload files verified; inactive menu modules/assets absent.")
    return manifest
if __name__=='__main__':verify()

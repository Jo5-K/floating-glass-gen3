from pathlib import Path
import hashlib,json,zipfile
from verify_package import verify
root=Path(__file__).resolve().parents[1]
manifest=verify();version=manifest['version'];dist=root/'dist';dist.mkdir(exist_ok=True)
archive=dist/f'Floating-Glass-Gen3-{version}.zip'
files=[p for p in (root/'floating_glass_frlg').rglob('*') if p.is_file()]
files += [root/name for name in ['README.md','LICENSE.md','THIRD_PARTY_NOTICES.md','Instalar.ps1','INSTALAR.cmd','ARQUIVOS.json','REMOVIDOS.json']]
files += list(root.glob('ATUALIZAR-DE-ALPHA*.json'))
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for path in sorted(files):z.write(path,path.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None,'ZIP CRC failure'
    for e in json.loads((root/'ARQUIVOS.json').read_text()):
        assert hashlib.sha256(z.read('floating_glass_frlg/'+e['path'])).hexdigest()==e['sha256']
checksum=hashlib.sha256(archive.read_bytes()).hexdigest()
(dist/'SHA256SUMS.txt').write_text(checksum+'  '+archive.name+'\n')
print(archive);print('ZIP CRC and archived payload SHA-256 verified.')

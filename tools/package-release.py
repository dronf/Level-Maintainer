"""Package an already built/verified JAR plus the staged project source and guides.

Stage new source/docs with git add before running; build artifacts stay outside Git.
Usage: python tools/package-release.py --jar /path/to/built.jar --output /path/to/release
"""
import argparse
import hashlib
import json
import pathlib
import re
import shutil
import subprocess
import zipfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--jar', type=pathlib.Path, required=True)
parser.add_argument('--output', type=pathlib.Path, required=True)
args = parser.parse_args()
repo = pathlib.Path(__file__).resolve().parents[1]
version = json.loads((repo / 'client/nei-level-maintainer/src/main/resources/mcmod.info').read_text())[0]['version']
tag = 'nei-level-maintainer-' + version
out = args.output.resolve()
out.mkdir(parents=True, exist_ok=True)
jar = out / (tag + '.jar')
if args.jar.resolve() != jar:
    shutil.copyfile(args.jar, jar)
with zipfile.ZipFile(jar) as z:
    assert z.testzip() is None
    assert json.loads(z.read('mcmod.info'))[0]['version'] == version
    classes = [n for n in z.namelist() if n.endswith('.class')]
    assert classes and all(n.startswith('dev/dronf/neilevel/') for n in classes)
    assert all(int.from_bytes(z.read(n)[6:8], 'big') == 52 for n in classes)
    assert all(n.startswith(('META-INF/', 'dev/')) or n == 'mcmod.info' for n in z.namelist())

tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=repo).decode().split('\0')
tracked = sorted(p for p in tracked if p and (repo / p).is_file())
for required in ('docs/INSTALLATION.md', 'docs/CONFIGURATION.md', 'tools/package-release.py'):
    assert required in tracked, 'Stage new release sources before packaging: ' + required
assert not any('/build/' in p or p.endswith(('.jar', '.zip', '.class')) for p in tracked)

source = out / (tag + '-source.zip')
with zipfile.ZipFile(source, 'w', zipfile.ZIP_DEFLATED) as z:
    for name in tracked:
        z.write(repo / name, 'Level-Maintainer-' + version + '/' + name)

def standalone(path):
    text = path.read_text(encoding='utf-8')
    def link(match):
        target = match.group(1)
        if re.match(r'[a-z]+:', target) or target.startswith('#'):
            return match.group(0)
        plain, sep, anchor = target.partition('#')
        relative = (path.parent / plain).resolve().relative_to(repo).as_posix()
        return '](' + 'https://github.com/dronf/Level-Maintainer/blob/' + tag + '/' + relative + (sep + anchor if sep else '') + ')'
    return re.sub(r'\]\(([^)]+)\)', link, text)

installation = out / ('INSTALLATION-' + version + '.md')
installation.write_text(standalone(repo / 'docs/INSTALLATION.md'), encoding='utf-8')
verification = out / ('VERIFICATION-' + version + '.md')
verification.write_text(standalone(repo / 'client' / ('VERIFICATION-' + version + '.md')), encoding='utf-8')
oc = out / ('level-maintainer-oc-' + version + '.zip')
with zipfile.ZipFile(oc, 'w', zipfile.ZIP_DEFLATED) as z:
    for name in ['Maintainer.lua', 'installer.lua', 'nei_bridge.lua',
                 'src/AE2.lua', 'src/Display.lua', 'src/Settings.lua', 'src/Utility.lua']:
        z.write(repo / name, name)
    for name in ['config.lua', 'settings.lua']:
        z.write(repo / name, name + '.example')
    z.writestr('INSTALLATION.md', installation.read_text(encoding='utf-8'))

guides = out / ('level-maintainer-docs-' + version + '.zip')
with zipfile.ZipFile(guides, 'w', zipfile.ZIP_DEFLATED) as z:
    for name in tracked:
        if name.endswith('.md') or name in ['docs/index.html', 'docs/config.js']:
            z.write(repo / name, name)

assets = [jar, source, oc, guides, installation, verification]
for artifact in assets:
    if artifact.suffix in ('.jar', '.zip'):
        with zipfile.ZipFile(artifact) as z:
            assert z.testzip() is None
    print(artifact.name, artifact.stat().st_size, 'bytes')
with zipfile.ZipFile(oc) as z:
    assert not {'config.lua', 'settings.lua', 'nei_overrides.lua'}.intersection(z.namelist())
(out / ('SHA256SUMS-' + version + '.txt')).write_text(''.join(
    hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + p.name + '\n' for p in assets
), encoding='utf-8')
print('PASS: metadata, Java 8 classes, addon namespace, archive CRCs, user-config exclusion and checksums')

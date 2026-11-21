"""Install pre-rendered brand resources after Flutter platform generation."""
import json, shutil, plistlib
from pathlib import Path
from decimal import Decimal
from xml.etree import ElementTree as ET
root=Path(__file__).resolve().parent.parent
icons=root/'scripts/icons'
for platform in ('ios','macos'):
    d=root/platform/'Runner/Assets.xcassets/AppIcon.appiconset'
    if not d.is_dir(): continue
    p=d/'Contents.json'; data=json.loads(p.read_text())
    for i in data['images']:
        n=int(Decimal(i['size'].split('x')[0])*Decimal(i.get('scale','1x').rstrip('x')))
        src=icons/(('alpha-' if platform=='macos' else '')+str(n)+'.png')
        if not src.exists(): raise ValueError(f'Unsupported icon size {platform} {n}')
        name=f'FinScope-{n}.png'; shutil.copyfile(src,d/name);i['filename']=name
    p.write_text(json.dumps(data,indent=2)+'\n')
    used={i['filename'] for i in data['images']}
    for old in d.glob('*.png'):
        if old.name not in used: old.unlink()
    if platform=='ios':
        p=root/'ios/Runner/Info.plist'; data=plistlib.loads(p.read_bytes());data['CFBundleDisplayName']='FinScope';p.write_bytes(plistlib.dumps(data))
for density,n in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    d=root/'android/app/src/main/res'/('mipmap-'+density)
    if d.is_dir(): shutil.copyfile(icons/f'{n}.png',d/'ic_launcher.png')
p=root/'android/app/src/main/AndroidManifest.xml'
if p.exists():
    s=p.read_text();s=s.replace('android:label="finscope"','android:label="FinScope"');p.write_text(s)
p=root/'macos/Runner/Configs/AppInfo.xcconfig'
if p.is_file():
    import re
    p.write_text(re.sub(r'(?m)^PRODUCT_NAME\s*=.*$', 'PRODUCT_NAME = FinScope', p.read_text()))
p=root/'windows/runner/resources/app_icon.ico'
if p.parent.is_dir(): shutil.copyfile(icons/'app_icon.ico',p)

"""Original cloth/engraving patterns on the project's credited outfit atlases."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,math
root=Path(__file__).resolve().parents[1]
gear=json.loads((root/'data/equipment.json').read_text());out=root/'assets/textures/equipment';out.mkdir(exist_ok=True)
for name,e in gear.items():
 if e['slot']!='Chest' or not e.get('theme'):continue
 for sex in ['male','female']:
  outfit='ranger' if e['theme'] in ['knight','shadow','nature'] else 'traveler'
  src=Image.open(root/f'assets/textures/class_skins/paladin_{sex}_{outfit}.webp').convert('RGB')
  tint=tuple(bytes.fromhex(e['color']));layer=Image.new('RGB',src.size,tint);src=Image.blend(src,layer,.48)
  draw=ImageDraw.Draw(src);w,h=src.size;accent=tuple(min(255,int(c*.65+90)) for c in tint)
  for x in range(0,w,48):
   if e['theme']=='knight':draw.line([(x,0),(x,h)],fill=accent,width=2)
   elif e['theme']=='shadow':draw.line([(x,0),(x+w,h)],fill=accent,width=1)
   else:
    for y in range(0,h,56):
     if e['theme']=='nature':draw.ellipse((x,y,x+10,y+22),outline=accent,width=2)
     elif e['theme']=='sun':
      draw.ellipse((x,y,x+18,y+18),outline=accent,width=2);draw.line((x+9,y-4,x+9,y+22),fill=accent,width=1)
     else:draw.polygon([(x+8,y),(x+15,y+12),(x+8,y+24),(x,y+12)],outline=accent,width=2)
  src.save(out/(e['id']+'_'+sex+'.webp'),quality=92)
(out/'README.md').write_text('Original equipment pattern derivatives created by tools/build_equipment_textiles.py from the existing credited CC0 Quaternius-derived class outfit atlases. Source grants remain in assets/vendor/SOURCES.json and class_skins/DERIVATIVES.json. No new third-party download. Patterns are cosmetic; original rigs and UVs are preserved.\n')

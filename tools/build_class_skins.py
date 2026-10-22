"""Reproducible class skins derived from the licensed CC0 outfit atlases.
Keeps authored geometry/normal/roughness; recolors fabric and stamps original class crests.
Requires Python, Pillow and numpy. No network or Blender dependency.
"""
from pathlib import Path
import io, json, struct, hashlib, math
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
CATALOG=json.loads((ROOT/'data/hero_skins.json').read_text())
OUT=ROOT/'assets/textures/class_skins'
OUT.mkdir(parents=True,exist_ok=True)
def glb(name):
    raw=(ROOT/'assets/vendor/quaternius/characters'/name).read_bytes()
    size=struct.unpack_from('<I',raw,12)[0]
    return json.loads(raw[20:20+size]),raw[28+size:]
def accessor(j,b,index):
    a=j['accessors'][index];v=j['bufferViews'][a['bufferView']]
    dtype={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']]
    cols={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
    off=v.get('byteOffset',0)+a.get('byteOffset',0)
    stride=v.get('byteStride',np.dtype(dtype).itemsize*cols)
    return np.ndarray((a['count'],cols),dtype=dtype,buffer=b,offset=off,strides=(stride,np.dtype(dtype).itemsize)).copy()
def original_atlas(j,b):
    idx=next(i for i,m in enumerate(j['materials']) if m['name'] in ['MI_Ranger','MI_Peasant'])
    tex=j['materials'][idx]['pbrMetallicRoughness']['baseColorTexture']['index']
    t=j['textures'][tex]
    source=t.get('source',t.get('extensions',{}).get('EXT_texture_webp',{}).get('source'))
    v=j['bufferViews'][j['images'][source]['bufferView']]
    return Image.open(io.BytesIO(b[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']])).convert('RGB')
def crest(kind,color):
    img=Image.new('RGBA',(128,128));d=ImageDraw.Draw(img);c='#'+color
    if kind=='sun':
        d.ellipse((43,43,85,85),outline=c,width=6)
        for i in range(8):
            a=i*math.tau/8;d.line([(64+math.cos(a)*30,64+math.sin(a)*30),(64+math.cos(a)*46,64+math.sin(a)*46)],fill=c,width=5)
    elif kind=='arrow':
        d.line((25,99,101,23),fill=c,width=6);d.line((65,23,101,23,101,59),fill=c,width=6)
        d.line((25,78,25,99,46,99),fill=c,width=5)
    elif kind=='leaf':
        d.polygon([(64,13),(91,45),(88,79),(64,110),(40,79),(37,45)],outline=c,width=6);d.line((64,29,64,103),fill=c,width=4)
    elif kind=='crossed':
        for x in [1,-1]:
            d.line((64-x*32,26,64+x*32,101),fill=c,width=8)
            d.line((64+x*13,79,64+x*37,58),fill=c,width=5)
    elif kind=='fang':d.polygon([(28,23),(58,43),(63,109),(84,49),(102,23),(96,84),(64,118),(30,83)],outline=c,width=5)
    elif kind=='star':
        pts=[(64+math.sin(i*math.pi/5)*(49 if i%2==0 else 21),64-math.cos(i*math.pi/5)*(49 if i%2==0 else 21)) for i in range(10)]
        d.polygon(pts,outline=c,width=5)
    elif kind=='flame':d.polygon([(63,10),(82,45),(102,60),(97,91),(64,112),(29,91),(25,67),(47,34),(47,72),(62,81),(72,62)],outline=c,width=5)
    elif kind=='cross':d.polygon([(53,18),(75,18),(75,53),(110,53),(110,75),(75,75),(75,110),(53,110),(53,75),(18,75),(18,53),(53,53)],outline=c,width=5)
    elif kind=='diamond':d.polygon([(64,12),(102,64),(64,116),(26,64)],outline=c,width=6);d.line((64,35,64,93),fill=c,width=4)
    elif kind=='crescent':
        # Crescent is drawn as a ring arc, avoiding a solid rectangle on the cloth.
        d.arc((21,15,109,109),70,288,fill=c,width=10);d.polygon([(82,21),(96,31),(99,44)],fill=c)
    elif kind=='lotus':
        for box in [(24,44,65,97),(63,44,104,97),(44,15,84,101)]:d.ellipse(box,outline=c,width=5)
        d.line((26,109,102,109),fill=c,width=5)
    else:
        d.polygon([(64,14),(101,35),(101,91),(64,113),(27,91),(27,35)],outline=c,width=5)
        d.line((64,30,64,99),fill=c,width=5);d.line((44,49,84,79),fill=c,width=5);d.line((84,49,44,79),fill=c,width=5)
    return img

def stamp_chest(image,j,b,emblem):
    """Project a small crest onto the FRONT of the existing skinned torso UVs."""
    pixels=np.asarray(image).copy();n=pixels.shape[0];badge=np.asarray(emblem);bh,bw=badge.shape[:2]
    mesh=next(m for m in j['meshes'] if m['name'].endswith('_Body'))
    for primitive in mesh['primitives']:
        pos=accessor(j,b,primitive['attributes']['POSITION']);uv=accessor(j,b,primitive['attributes']['TEXCOORD_0'])
        norm=accessor(j,b,primitive['attributes']['NORMAL']);indices=accessor(j,b,primitive['indices']).reshape(-1,3)
        # Chest, above belts; same scale in the authored male/female rigs.
        center=1.49 if any(m["name"].startswith("Male_") for m in j["meshes"]) else 1.435
        center_x=.075
        for tri in indices:
            p=pos[tri];t=uv[tri]*n
            if norm[tri,2].mean()<.4:continue
            if p[:,0].min()>center_x+.055 or p[:,0].max()<center_x-.055 or p[:,1].min()>center+.055 or p[:,1].max()<center-.055:continue
            x0=max(0,int(t[:,0].min()));x1=min(n-1,int(t[:,0].max())+1)
            y0=max(0,int(t[:,1].min()));y1=min(n-1,int(t[:,1].max())+1)
            if x0>x1 or y0>y1:continue
            xx,yy=np.meshgrid(np.arange(x0,x1+1)+.5,np.arange(y0,y1+1)+.5)
            v0=t[1]-t[0];v1=t[2]-t[0];det=v0[0]*v1[1]-v1[0]*v0[1]
            if abs(det)<1e-6:continue
            dx=xx-t[0,0];dy=yy-t[0,1]
            a=(dx*v1[1]-v1[0]*dy)/det;c=(v0[0]*dy-dx*v0[1])/det
            xyz=p[0]+a[:,:,None]*(p[1]-p[0])+c[:,:,None]*(p[2]-p[0])
            bx=(((xyz[:,:,0]-center_x)/.11+.5)*(bw-1)).astype(int)
            by=((.5-(xyz[:,:,1]-center)/.11)*(bh-1)).astype(int)
            mask=(a>=0)&(c>=0)&(a+c<=1)&(bx>=0)&(bx<bw)&(by>=0)&(by<bh)
            samples=badge[np.clip(by,0,bh-1),np.clip(bx,0,bw-1)]
            mask&=samples[:,:,3]>0
            dest=pixels[y0:y1+1,x0:x1+1]
            # Keep existing fabric shading visible through the embroidery.
            shade=np.clip(np.mean(dest,axis=2)/140,.45,1)
            dyed=np.clip(samples[:,:,:3]*shade[:,:,None],0,255).astype(np.uint8)
            dest[mask]=dyed[mask]
    return Image.fromarray(pixels)

def recolor(image,profile,family):
    a=np.asarray(image).astype(float)/255
    r,g,b=a[:,:,0],a[:,:,1],a[:,:,2]
    hi=a.max(2);lo=a.min(2);sat=(hi-lo)/np.maximum(hi,.001)
    primary=(g>r*1.03)&(g>b*.98)&(sat>.14) if family=='ranger' else (sat<.36)&(hi>.24)&(hi<.89)
    leather=(r>g*1.08)&(g>b*.85)&(sat>.25)
    dark=(primary&(hi<.23)) if family=='ranger' else (leather&(hi<.25))
    result=a.copy()
    def apply(mask,key,shade):
        color=np.array([int(profile[key][i:i+2],16)/255 for i in [0,2,4]])
        result[mask]=np.clip(color[None,:]*shade[mask,None],0,1)
    apply(primary,'cloth',np.clip(hi/(.43 if family=='ranger' else .58),.35,1.35))
    apply(leather,'accent',np.clip(hi/.48,.35,1.1))
    apply(dark,'dark',np.clip(hi/.16,.45,1.3))
    return Image.fromarray((result*255).astype('uint8'))
manifest={}
for sex in ['Male','Female']:
    for family,label in [('ranger','ranger'),('peasant','traveler')]:
        name=f'{sex.lower()}_{family}.glb';j,b=glb(name);source=original_atlas(j,b)
        for class_,definition in CATALOG.items():
            profile=definition[sex]
            badge=crest(definition['motif'],profile['accent'])
            target=stamp_chest(recolor(source,profile,family),j,b,badge)
            path=OUT/f"{profile['id']}_{label}.webp"
            target.save(path,format='WEBP',quality=94,method=6)
            manifest[str(path.relative_to(ROOT))]={'source_model':name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'class':class_,'sex':sex,'outfit':label}
            if family=='ranger':badge.save(OUT/f"{profile['id']}_crest.png")
(OUT/'DERIVATIVES.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(f'Generated {len(manifest)} themed outfit atlases and 24 original crest textures.')

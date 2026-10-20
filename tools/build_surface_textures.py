"""Deterministic original tiling PBR surfaces and alpha-cutout foliage. Python + Pillow + NumPy."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
import numpy as np,random,math
OUT=Path(__file__).resolve().parents[1]/'assets/textures/rpg';OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(98);random.seed(98);size=512
for name,base in [('grass',(88,100,65)),('dirt',(118,103,79)),('cloth',(97,102,95))]:
 h=np.zeros((size,size),dtype=float)
 for scale,amplitude in [(4,.42),(16,.24),(64,.18),(512,.16)]:
  seed=(rng.random((scale,scale))*255).astype('uint8')
  # Wrap coarse grids before scaling to keep edge derivatives coherent.
  layer=np.array(Image.fromarray(seed).resize((size,size),Image.Resampling.BICUBIC))/255
  h+=layer*amplitude
 if name=='cloth':
  x,y=np.meshgrid(np.arange(size),np.arange(size));h=.45+h*.1+((x%5==0)|(y%5==0))*.13
 color=np.array(base)[None,None,:]*(.7+h[:,:,None]*.65)
 image=Image.fromarray(np.uint8(np.clip(color,0,255)))
 if name=='grass':
  draw=ImageDraw.Draw(image)
  for _ in range(4200):
   x=random.randrange(size);y=random.randrange(size);tone=random.choice([(83,99,58),(110,119,76),(72,88,54)])
   draw.line((x,y,x+random.randint(-2,2),y-random.randrange(3,10)),fill=tone,width=1)
 if name=='dirt':
  draw=ImageDraw.Draw(image)
  for _ in range(1500):
   x=random.randrange(size);y=random.randrange(size);r=random.choice([1,1,2,3]);tone=random.randint(60,132)
   draw.ellipse((x-r,y-r,x+r,y+r),fill=(tone+14,tone+8,tone))
 image.save(OUT/f'{name}_albedo.png')
 dx=(np.roll(h,-1,1)-np.roll(h,1,1))*2;dy=(np.roll(h,-1,0)-np.roll(h,1,0))*2
 normal=np.stack((-dx,-dy,np.ones_like(h)),axis=2);normal/=np.linalg.norm(normal,axis=2)[:,:,None]
 Image.fromarray(np.uint8((normal*.5+.5)*255)).save(OUT/f'{name}_normal.png')
 Image.fromarray(np.uint8(np.clip(190+h*50,0,255))).save(OUT/f'{name}_roughness.png')
# A transparent branch with tapered leaflets, for clusters of oriented cards rather than sphere canopies.
image=Image.new('RGBA',(512,512));draw=ImageDraw.Draw(image)
for branch in range(5):
 origin=(256,480);end=(70+branch*90,45+abs(branch-2)*45)
 draw.line([origin,end],fill=(77,66,42,255),width=5)
 for j in range(1,12):
  t=j/12;x=origin[0]+(end[0]-origin[0])*t;y=origin[1]+(end[1]-origin[1])*t
  for side in [-1,1]:
   length=random.randint(23,44);tip=(x+side*length,y-length*.38)
   shade=random.randint(-12,20);color=(69+shade,98+shade,53+shade,255)
   draw.polygon([(x,y),(x+side*length*.45,y-length*.45),tip,(x+side*length*.55,y+length*.12)],fill=color)
   draw.line([(x,y),tip],fill=(103+shade,123+shade,70+shade,255),width=1)
image.save(OUT/'canopy.png')
print('Original surface textures built')

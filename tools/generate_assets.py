"""Generate original tileable surface textures, vector portraits and synthesized music.
Requires Python, Pillow and numpy only to regenerate; Godot uses the checked-in files.
"""
from pathlib import Path
import math, wave
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
ROOT=Path(__file__).resolve().parents[1]
rng=np.random.default_rng(392)
for kind,base in {'grass':(169,183,144),'stone':(184,184,172),'wood':(187,160,123),'fabric':(195,191,181),'metal':(202,210,216),'tile':(190,185,170)}.items():
 n=256
 noise=rng.normal(0,5,(n,n,1))
 a=np.clip(np.array(base)[None,None,:]+noise,0,255).astype('uint8')
 im=Image.fromarray(a);d=ImageDraw.Draw(im,'RGBA')
 if kind=='grass':
  for _ in range(1600):
   x,y=rng.integers(0,n,2);d.line((int(x),int(y),int(x+2),int(y-5)),fill=(75,108,55,50),width=1)
 elif kind in ('stone','tile'):
  for y in range(0,n,64):
   d.line((0,y,n,y),fill=(60,65,61,90),width=3)
   for x in range(-64,n,128):
    x+=32 if (y//64)%2 else 0
    d.line((x,y,x,y+64),fill=(60,65,61,90),width=3)
  for _ in range(100):
   x,y=rng.integers(0,n,2);d.ellipse((int(x),int(y),int(x+5),int(y+2)),fill=(80,95,66,25))
 elif kind=='wood':
  for x in range(0,n,32): d.line((x,0,x,n),fill=(58,36,18,90),width=2)
  for _ in range(160):
   x,y=rng.integers(0,n,2);d.line((int(x),int(y),int(x+math.sin(y)*3),int(y+40)),fill=(87,57,27,40))
 elif kind=='fabric':
  for x in range(0,n,4): d.line((x,0,x,n),fill=(255,255,240,25))
  for y in range(0,n,4): d.line((0,y,n,y),fill=(70,60,60,20))
 elif kind=='metal':
  for y in range(0,n,2):d.line((0,y,n,y),fill=(255,255,255,12))
 im.save(ROOT/'assets/textures'/f'{kind}.png')
# Layered original SVG portrait illustrations.
for name in ['Hero','Mira','Wolf','Warden']:
 background='<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><defs><linearGradient id="bg" x2="0" y2="1"><stop stop-color="#365c68"/><stop offset="1" stop-color="#152738"/></linearGradient></defs><rect width="256" height="256" rx="20" fill="url(#bg)"/><circle cx="128" cy="107" r="82" fill="#b5be8a" opacity=".14"/>'
 if name in ('Mira','Hero'):
  hair='#b66d46' if name=='Mira' else '#674837';coat='#637c65' if name=='Mira' else '#718da9'
  art=f'<path d="M39 256Q36 183 87 177L169 177Q220 189 220 256" fill="{coat}"/><path d="M74 155Q48 68 96 44Q169 19 192 84L183 194L155 162" fill="{hair}"/><path d="M103 161L103 191L128 211L154 187L152 156" fill="#d99e7e"/><ellipse cx="128" cy="117" rx="53" ry="64" fill="#f1c5a0"/><path d="M75 113Q64 54 109 45Q176 22 186 101L164 88L145 66Q126 106 75 113" fill="{hair}"/><path d="M93 119Q102 111 113 119M144 119Q154 110 166 119" fill="none" stroke="#4a3936" stroke-width="4"/><ellipse cx="104" cy="125" rx="5" ry="7" fill="#375260"/><ellipse cx="155" cy="125" rx="5" ry="7" fill="#375260"/><path d="M123 144L132 145M113 160Q130 171 146 157" fill="none" stroke="#b97865" stroke-width="3"/><path d="M64 213L98 188L128 218L159 188L194 214" fill="none" stroke="#dfc38a" stroke-width="6"/>'
  if name=='Mira':art+='<path d="M75 84Q61 44 96 45Q103 68 75 84" fill="#94b875"/><circle cx="81" cy="72" r="8" fill="#d2a2d0"/>'
 else:
  if name=='Wolf':
   art='<path d="M48 224L65 54L107 101L152 101L196 49L212 226Z" fill="#94acb9"/><path d="M66 88L77 126L96 110M181 86L166 110L190 127" fill="#d6c4bd"/><path d="M72 153L107 142L126 190L151 142L188 152L174 222L128 244L83 220" fill="#dce4df"/><path d="M90 148L110 154M150 154L172 147" stroke="#e8bc5c" stroke-width="9"/><path d="M113 197L145 197L128 215Z" fill="#2d3e49"/>'
  else:
   art='<path d="M53 256L65 109L41 67L62 55L85 95L97 52L118 28L128 75L151 52L183 36L171 85L202 67L216 89L181 125L204 256Z" fill="#716b50"/><path d="M85 139L111 145M145 145L172 132" stroke="#91ead0" stroke-width="10"/><path d="M107 187L150 178L145 211L117 217Z" fill="#303d36"/><path d="M73 110L118 129L129 189M166 89L140 122L145 164M87 217L105 241M165 199L179 249" fill="none" stroke="#9e9672" stroke-width="7"/><circle cx="128" cy="238" r="18" fill="#9fe4be"/>'
 (ROOT/'assets/portraits'/f'{name.lower()}.svg').write_text(background+art+'<rect x="5" y="5" width="246" height="246" rx="17" fill="none" stroke="#c1ac78" stroke-width="5"/></svg>')
RATE=22050
def save_audio(name,a,loop=False):
 a=np.clip(a,-.92,.92)
 with wave.open(str(ROOT/'assets/audio'/f'{name}.wav'),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes((a*32767).astype('<i2').tobytes())
def note(buf,start,length,midi,volume=.15,soft=False):
 offset=int(start*RATE); count=min(int(length*RATE),len(buf)-offset)
 t=np.arange(count)/RATE;freq=440*2**((midi-69)/12)
 envelope=np.minimum(t/.03,1)*np.minimum((length-t)/.12,1)
 tone=np.sin(2*np.pi*freq*t)+.23*np.sin(2*np.pi*freq*2*t)+.09*np.sin(2*np.pi*freq*3*t)
 if soft:envelope*=np.exp(-t*1.5)
 buf[offset:offset+count]+=tone*envelope*volume
for name,tempo,progression in [('woodland',90,[48,53,55,48,57,53,55,48]),('sanctuary',72,[45,50,41,45,48,43,50,45]),('battle',120,[45,45,53,55,45,48,50,52])]:
 beat=60/tempo;duration=beat*32;audio=np.zeros(round(RATE*duration))
 melody=[12,16,19,24,21,19,16,14]
 for bar,root in enumerate(progression):
  for interval in [0,7,12]:note(audio,bar*beat*4,beat*3.9,root+interval,.045)
  for j in range(4):
   note(audio,(bar*4+j)*beat,beat*.85,root+melody[(bar+j)%8],.10,True)
   if name=='battle':
    note(audio,(bar*4+j)*beat,beat*.4,root-12,.10,True)
 save_audio(name,audio)
for name,notes in [('confirm',[72,76]),('hit',[43,36]),('heal',[72,76,79]),('victory',[60,64,67,72,76,79]),('step',[32])]:
 a=np.zeros(int(RATE*(len(notes)*.12+.3)))
 for i,n in enumerate(notes):note(a,i*.12,.23,n,.18,True)
 save_audio(name,a)
print('Generated six original textures, four portraits, three music loops and five cues.')

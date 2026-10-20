"""Original demo art. Run: blender --background --factory-startup --python tools/build_rpg_art.py
Creature/gear geometry is original. Hero variants derive from CC0 KayKit rigs.
"""
import bpy, math, json, random
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
random.seed(814)
MATS={}
def coord(v): return Vector((v[0],-v[2],v[1]))
def reset():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 MATS.clear()
def mat(name,color,metal=0,rough=.65):
 if name in MATS:return MATS[name]
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 MATS[name]=m;return m
silver=lambda:mat('Forged silver steel',(.42,.51,.56),.82,.28)
gold=lambda:mat('Aged brass inlay',(.54,.36,.13),.75,.32)
wood=lambda:mat('Oiled walnut',(.18,.095,.048),0,.66)
leather=lambda:mat('Tooled leather',(.16,.075,.035),0,.82)
def colorhex(h):return tuple(int(h[i:i+2],16)/255 for i in (0,2,4))
def finish(o,m,parent=None):
 o.data.materials.append(m)
 for p in o.data.polygons:p.use_smooth=True
 if parent:o.parent=parent
 return o
def ell(name,pos,scale,m,parent=None):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=coord(pos))
 o=bpy.context.object;o.name=name;o.scale=(scale[0],scale[2],scale[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return finish(o,m,parent)
def empty(name):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);return o
def beam(name,a,b,r,m,parent=None,r2=None):
 a,b=coord(a),coord(b);delta=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=r,radius2=r if r2 is None else r2,depth=delta.length,location=(a+b)/2)
 o=bpy.context.object;o.name=name;o.rotation_euler=delta.to_track_quat('Z','Y').to_euler()
 bevel=o.modifiers.new('Forged softened edges','BEVEL');bevel.width=.012;bevel.segments=2
 return finish(o,m,parent)
def curve(name,pts,r,m,parent=None):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=2;c.resolution_u=10
 spline=c.splines.new('BEZIER');spline.bezier_points.add(len(pts)-1)
 for p,v in zip(spline.bezier_points,pts):p.co=coord(v);p.handle_left_type='AUTO';p.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.parent=parent;c.materials.append(m)
 # glTF requires mesh for curves.
 bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False)
 return o
def mesh(name,verts,faces,m,parent=None,bevel=0):
 data=bpy.data.meshes.new(name);data.from_pydata([coord(v) for v in verts],[],faces);data.update()
 o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o)
 finish(o,m,parent)
 if bevel:
  mod=o.modifiers.new('Edge highlights','BEVEL');mod.width=bevel;mod.segments=2
 return o
def loft(name,sections,m,parent=None,sides=16):
 # Sections: center x,y,z then horizontal and depth radii.
 verts=[];faces=[]
 for x,y,z,rx,rz in sections:
  for i in range(sides):
   angle=i*math.tau/sides;verts.append((x+math.cos(angle)*rx,y,z+math.sin(angle)*rz))
 for j in range(len(sections)-1):
  for i in range(sides):
   a=j*sides+i;b=j*sides+(i+1)%sides;faces.append((a,b,b+sides,a+sides))
 faces.append(tuple(reversed(range(sides))));faces.append(tuple((len(sections)-1)*sides+i for i in range(sides)))
 return mesh(name,verts,faces,m,parent)
def blade(name,length,width,m,parent=None):
 verts=[]
 for y,w in [(.12,width*.6),(.23,width),(.23+length*.75,width*.72),(.23+length,0.005)]:
  verts.extend([(-w/2,y,0),(0,y,-.045),(w/2,y,0),(0,y,.045)])
 faces=[]
 for j in range(3):
  for k in range(4):faces.append((j*4+k,j*4+(k+1)%4,(j+1)*4+(k+1)%4,(j+1)*4+k))
 faces+=[(3,2,1,0),(12,13,14,15)]
 return mesh(name,verts,faces,m,parent,.005)
def export(path):
 path.parent.mkdir(parents=True,exist_ok=True)
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animations=True,export_yup=True,export_apply=True)
def gear(name,e):
 reset();root=empty('Item');c=mat('Item enamel',colorhex(e['color']),.3,.38);s=silver();g=gold();w=wood();l=leather();slot=e['slot'];family=e.get('weapon_type','')
 if slot=='Weapon':
  if family in ['sword','greatsword','dagger']:
   blade('Tempered diamond edge',1.45 if family=='greatsword' else (.58 if family=='dagger' else 1.08),.28 if family=='greatsword' else .15,s,root)
   curve('Swept quillons',[(-.27,.15,.02),(-.15,.08,0),(0,.12,0),(.15,.08,0),(.27,.15,.02)],.035,g,root)
   beam('Leather grip',(0,-.28,0),(0,.12,0),.055,l,root)
   for i in range(7):curve('Bound grip',[(math.cos(a)*.059,-.26+i*.048,math.sin(a)*.059) for a in [j*math.tau/16 for j in range(17)]],.008,g,root)
   ell('Pommel',(0,-.32,0),(.09,.095,.075),g,root)
   curve('Inlaid fuller',[(0,.25,-.047),(0,.8,-.047),(0,1.05 if family!='dagger' else .67,-.047)],.009,c,root)
  elif family=='bow':
   for side in [-1,1]:
    curve('Recurved yew limb',[(0,0,0),(.1,side*.35,0),(.28,side*.72,0),(.18,side*.98,0)],.038,w,root)
    curve('Silver limb inlay',[(0,0,-.035),(.1,side*.35,-.035),(.28,side*.72,-.035),(.18,side*.98,-.035)],.011,g,root)
   curve('Bowstring',[(.18,-.98,0),(-.15,0,0),(.18,.98,0)],.006,mat('Flax string',(.7,.65,.48)),root)
   beam('Wrapped handle',(0,-.14,0),(0,.14,0),.058,l,root)
  elif family in ['staff','wand','spear','scythe']:
   length=1.95 if family!='wand' else .65
   beam('Carved shaft',(0,-length*.45,0),(0,length*.55,0),.042,w,root,r2=.033)
   for y in [-length*.35,0,length*.48]:beam('Brass ferrule',(0,y-.045,0),(0,y+.045,0),.05,g,root)
   top=length*.55
   if family in ['staff','wand']:
    for side in [-1,1]:curve('Crescent cradle',[(0,top-.1,0),(side*.16,top+.08,0),(side*.1,top+.35,0)],.023,g,root)
    ell('Moonstone',(0,top+.17,0),(.085,.16,.085),mat('Blue moonstone',(.12,.42,.57),.3,.18),root)
    curve('Vine engraving',[(math.sin(i*.8)*.048,-length*.3+i*length*.065,math.cos(i*.8)*.048) for i in range(13)],.008,c,root)
   elif family=='spear':
    obj=blade('Leaf spearhead',.52,.22,s,root);obj.location=coord((0,top-.15,0))
   else:
    mesh('Harvesting crescent',[(0,top,0),(.18,top+.12,0),(.65,top+.04,0),(.83,top-.24,0),(.5,top-.1,0),(.15,top-.04,0)],[(0,1,2,3,4,5)],s,root,.01)
    beam('Scythe collar',(-.07,top,0),(.15,top,0),.07,g,root)
  elif family in ['axe','hammer','mace']:
   beam('Bound haft',(0,-.3,0),(0,.85,0),.045,w,root)
   for y in [-.23,-.12,-.01,.1]:beam('Grip binding',(0,y,0),(0,y+.018,0),.052,l,root)
   if family=='axe':
    profile=[(-.06,.68),(.13,.97),(.4,1.03),(.54,.86),(.55,.62),(.4,.42),(.12,.56)]
    verts=[(x,y,z) for z in [-.055,.055] for x,y in profile];n=len(profile);faces=[tuple(range(n)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh('Bearded axe head',verts,faces,s,root,.018)
    beam('Axe eye',(0,.6,0),(0,.9,0),.095,g,root)
   elif family=='hammer':
    ell('Warhammer head',(0,.75,0),(.36,.19,.18),s,root)
    for x in [-.3,.3]:ell('Fluted striking face',(x,.75,0),(.09,.2,.19),g,root)
   else:
    ell('Flanged mace core',(0,.75,0),(.15,.2,.15),s,root)
    for i in range(6):
     a=i*math.tau/6;beam('Mace flange',(math.sin(a)*.19,.6,math.cos(a)*.19),(math.sin(a)*.19,.9,math.cos(a)*.19),.045,g,root)
  elif family=='claws':
   ell('Claw gauntlet',(0,0,0),(.2,.17,.12),l,root)
   for i in [-1,0,1]:curve('Curved talon',[(i*.115,.05,-.07),(i*.12,.35,-.1),(i*.12,.62,-.23)],.025,s,root)
   curve('Knuckle guard',[(-.22,.12,0),(0,.2,-.12),(.22,.12,0)],.025,g,root)
 elif slot=='Shield':
  is_round=e['style']=='round'
  if is_round:
   ell('Oak shield',(0,0,0),(.43,.43,.065),w,root)
   curve('Brass rim',[(math.sin(i*math.tau/48)*.44,math.cos(i*math.tau/48)*.44,-.015) for i in range(49)],.025,g,root)
  else:
   mesh('Kite shield',[(-.42,.4,0),(.42,.4,0),(.38,-.1,0),(0,-.62,-.07),(-.38,-.1,0),(0,.18,-.1)],[(0,1,5),(1,2,5),(2,3,5),(3,4,5),(4,0,5)],c,root,.02)
   curve('Shield edge',[(-.42,.4,-.02),(.42,.4,-.02),(.38,-.1,-.02),(0,-.62,-.09),(-.38,-.1,-.02),(-.42,.4,-.02)],.024,g,root)
  ell('Steel boss',(0,.05,-.08),(.13,.13,.07),s,root)
  for x in [-.15,.15]:beam('Emblem ray',(0,.05,-.14),(x,.28,-.05),.018,g,root)
 elif slot=='Chest':
  armor=s if e['style']=='plate' else (c if e['style']=='robe' else l)
  loft('Shaped breastplate',[(0,-.35,0,.27,.16),(0,-.15,0,.32,.19),(0,.2,0,.43,.22),(0,.44,0,.35,.16)],armor,root)
  curve('Neckline',[(-.28,.44,-.12),(0,.33,-.23),(.28,.44,-.12)],.025,g,root)
  for side in [-1,1]:
   ell('Layered pauldron',(side*.4,.3,0),(.22,.17,.24),armor,root)
   curve('Pauldron trim',[(side*.25,.32,-.18),(side*.43,.34,-.24),(side*.58,.24,-.1)],.018,g,root)
   beam('Leather fastening',(side*.23,-.3,-.15),(side*.27,.33,-.18),.018,l,root)
  beam('Waist belt',(-.27,-.2,-.17),(.27,-.2,-.17),.035,l,root)
  ell('Sunburst clasp',(0,-.2,-.21),(.07,.07,.025),g,root)
  if e['style']=='robe':loft('Woven flowing skirt',[(0,-.35,0,.27,.18),(0,-.65,0,.4,.27),(0,-1.05,0,.52,.33)],c,root)
  else:
   for side in [-1,1]:loft('Laminated hip guard',[(side*.2,-.3,0,.16,.18),(side*.24,-.5,0,.2,.2)],armor,root)
 elif slot=='Helmet':
  armor=s if e['style']=='plate' else c
  verts=[];faces=[];cols=28;rows=9
  for j in range(rows+1):
   theta=.06+j*1.65/rows
   for i in range(cols+1):
    # Front opening, with a closed crown.
    phi=.55+i*(math.tau-1.1)/cols
    verts.append((.35*math.sin(theta)*math.sin(phi),.4*math.cos(theta),-.32*math.sin(theta)*math.cos(phi)))
  for j in range(rows):
   for i in range(cols):
    a=j*(cols+1)+i;faces.append((a,a+1,a+cols+2,a+cols+1))
  mesh('Open faced helm',verts,faces,armor,root)
  curve('Brow band',[(-.24,.12,-.23),(0,.18,-.34),(.24,.12,-.23)],.027,g,root)
  if e['style']=='plate':curve('Crest ridge',[(0,.14,-.31),(0,.4,-.05),(0,.25,.29)],.035,g,root)
 elif slot in ['Gauntlets','Pants','Boots']:
  armor=s if e['style']=='plate' else l
  for side in [-1,1]:
   x=side*.18
   loft('Articulated shell',[(x,-.3,0,.13,.12),(x,0,0,.15,.14),(x,.3,0,.12,.1)],armor,root)
   for y in [-.18,-.06,.06,.18]:curve('Panel piping',[(x-.1,y,-.08),(x,y,-.15),(x+.1,y,-.08)],.012,g,root)
   if slot=='Boots':ell('Leather sole',(x,-.29,-.08),(.14,.075,.23),l,root)
   if slot=='Gauntlets':ell('Knuckle plates',(x,-.22,-.08),(.14,.12,.12),armor,root)
 else:
  curve('Pendant chain',[(math.sin(i*math.tau/40)*.23,.26+math.cos(i*math.tau/40)*.3,0) for i in range(41)],.012,g,root)
  ell('Engraved bezel',(0,-.1,0),(.14,.19,.04),g,root)
  ell('Cut gemstone',(0,-.1,-.04),(.105,.15,.04),c,root)
 export(ROOT/'assets/models/gear'/f"{e['id']}.glb")
def fuse(parts,name,material,parent):
 bpy.ops.object.select_all(action='DESELECT')
 for p in parts:p.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 rem=o.modifiers.new('Sculpted organic union','REMESH');rem.mode='VOXEL';rem.voxel_size=.045;rem.use_smooth_shade=True
 bpy.ops.object.modifier_apply(modifier=rem.name)
 smooth=o.modifiers.new('Sculpt polish','SMOOTH');smooth.factor=1.5;smooth.iterations=4;bpy.ops.object.modifier_apply(modifier=smooth.name)
 dec=o.modifiers.new('Game topology','DECIMATE');dec.ratio=.5;bpy.ops.object.modifier_apply(modifier=dec.name)
 o.data.materials.clear();o.data.materials.append(material);o.parent=parent
 for p in o.data.polygons:p.use_smooth=True
 return o
def creature(id):
 reset();root=empty('Companion');body=empty('Body');body.parent=root
 palettes={'intro_wolf':(.22,.27,.3),'dire_wolf':(.045,.065,.085),'spirit_fox':(.62,.69,.61),'dragon':(.06,.15,.13),'griffin':(.34,.23,.12),'warhorse':(.24,.13,.075),'golem':(.2,.25,.24),'bristleback':(.23,.17,.12)}
 fur=mat('Sculpted hide',palettes[id],.05,.82);dark=mat('Dark muzzle',(.045,.05,.05),0,.55);ivory=mat('Horn and claw',(.7,.63,.45),0,.55);eye=mat('Amber eyes',(.8,.47,.12),.15,.23);white=mat('Cream feathers',(.65,.62,.49),0,.9)
 if id=='golem':
  rock=mat('Weathered granite',(.26,.31,.28),.1,.9)
  ell('Stone ribcage',(0,1.2,0),(.58,.7,.33),rock,body)
  ell('Ancient brow',(0,2.03,0),(.34,.33,.29),rock,body)
  for side in [-1,1]:
   ell('Shoulder tor',(side*.57,1.68,0),(.33,.32,.32),rock,body)
   limb=empty('Arm_'+str(side));limb.location=coord((side*.58,1.45,0));limb.parent=body
   ell('Granite forearm',(side*.74,1,0),(.25,.44,.26),rock,body)
   ell('Stone fist',(side*.8,.66,-.03),(.29,.25,.29),rock,body)
   ell('Golem leg',(side*.28,.43,0),(.24,.45,.29),rock,body)
   for y in [.82,1.15,1.5]:curve('Runic seam',[(side*.3,y,-.32),(side*.12,y+.07,-.34),(0,y,-.36)],.014,mat('Jade rune',(.16,.65,.52),.2,.3),body)
   ell('Luminous gaze',(side*.12,2.08,-.27),(.055,.027,.025),mat('Jade rune',(.16,.65,.52),.2,.3),body)
  for i in range(6):ell('Overgrown moss',(random.uniform(-.45,.45),random.uniform(1.35,1.75),random.uniform(-.2,.2)),(.12,.08,.14),mat('Old moss',(.22,.29,.12)),body)
 else:
  horse=id=='warhorse';fox=id=='spirit_fox';boar=id=='bristleback';dragon=id=='dragon';griffin=id=='griffin'
  height=1.25 if horse else (.7 if fox else .9)
  parts=[ell('Ribcage',(0,height,0),(.32 if not boar else .42,.38,.7),fur),ell('Haunch',(0,height*.9,.43),(.34,.4,.4),fur)]
  if horse:
   parts.extend([ell('Arched neck',(0,1.65,-.55),(.24,.58,.28),fur),ell('Equine skull',(0,2.07,-.76),(.23,.33,.3),fur),ell('Long muzzle',(0,1.88,-1.02),(.2,.23,.3),fur)])
  elif dragon:
   parts.extend([ell('Reptile neck',(0,1.2,-.45),(.23,.5,.26),fur),ell('Horned skull',(0,1.58,-.68),(.26,.25,.4),fur),ell('Reptile muzzle',(0,1.45,-1.04),(.23,.16,.34),fur)])
  elif griffin:
   parts.extend([ell('Feathered breast',(0,1.13,-.4),(.39,.56,.38),white),ell('Eagle skull',(0,1.65,-.63),(.28,.34,.29),white)])
  else:
   parts.extend([ell('Shoulder muscles',(0,height+.12,-.4),(.35,.43,.35),fur),ell('Sloping neck',(0,height+.28,-.55),(.25,.42,.28),fur),ell('Long skull',(0,height+.45,-.76),(.27,.27,.32),fur),ell('Muzzle',(0,height+.32,-1.02),(.19,.16,.27),fur)])
  fuse(parts,'Sculpted anatomy',fur,body)
  head_y=2.13 if horse else (1.7 if griffin else (1.65 if dragon else height+.49))
  if griffin:
   ell('Eagle feather crown',(0,1.65,-.63),(.29,.35,.3),white,body)
   curve('Hooked golden beak',[(0,1.65,-.83),(0,1.55,-1.08),(0,1.39,-1.04)],.085,ivory,body)
  else:
   ell('Wet nose',(0,head_y-.17,(-1.39 if dragon else -1.32) if not horse else -1.31),(.12,.075,.065),dark,body)
   curve('Muzzle seam',[(-.16,head_y-.24,-1.22),(0,head_y-.26,-1.35),(.16,head_y-.24,-1.22)],.009,dark,body)
  for side in [-1,1]:
   x=side*(.27 if not horse else .2)
   ell('Eye socket',(x,head_y,-.87),(.075,.06,.055),dark,body)
   ell('Iris',(x*1.03,head_y+.01,-.9),(.035,.029,.032),eye,body)
   ell('Pupil',(x*1.04,head_y+.01,-.925),(.012,.022,.01),dark,body)
   if not griffin and not dragon:
    ear_y=head_y+.39 if fox or horse else head_y+.24
    mesh('Pointed ear',[(side*.1,head_y+.1,-.69),(side*.29,head_y+.08,-.55),(side*.23,ear_y,-.6),(side*.18,head_y+.11,-.51)],[(0,1,2),(1,3,2),(3,0,2),(0,3,1)],fur,body)
    mesh('Ear lining',[(side*.13,head_y+.11,-.695),(side*.26,head_y+.11,-.565),(side*.23,ear_y-.06,-.613)],[(0,1,2)],mat('Ear leather',(.32,.24,.23)),body)
   if dragon:
    curve('Swept horn',[(side*.22,head_y+.1,-.6),(side*.3,head_y+.42,-.37),(side*.25,head_y+.56,-.16)],.05,ivory,body)
   for z in [-.42,.43]:
    hip=(side*.25,height-.08,z);knee=(side*.28,height*.48,z+(.12 if z>0 else -.04));ankle=(side*.28,.15,z-.04)
    limb=empty('Leg_'+str(side)+'_'+str(z));limb.parent=body;limb.location=coord(hip)
    segments=[]
    # Build at world coordinates then parent while preserving transform around the hip pivot.
    for name,a,b,r in [('Upper leg',hip,knee,.115 if not horse else .12),('Lower leg',knee,ankle,.065 if not boar else .09)]:segments.append(beam(name,a,b,r,fur,r2=r*.65))
    segments.append(ell('Paw',(ankle[0],.1,ankle[2]-.09),(.125,.095,.19),dark if horse else fur))
    for o in segments:
     o.parent=limb;o.matrix_parent_inverse=limb.matrix_world.inverted()
    if not horse:
     for toe in [-1,0,1]:beam('Claw',(ankle[0]+toe*.06,.07,ankle[2]-.2),(ankle[0]+toe*.06,.065,ankle[2]-.29),.018,ivory,body,r2=.002)
  if dragon:
   curve('Long scaled tail',[(0,.85,.6),(.1,.65,1.2),(.3,.36,2),(.5,.55,2.5)],.085,fur,body)
   for j in range(6):ell('Throat scale',(0,1.3-j*.085,-.72+j*.045),(.18,.065,.055),ivory,body)
  tails=3 if fox else (0 if dragon else 1)
  for i in range(tails):
   spread=(i-(tails-1)/2)*.5
   curve('Flowing tail',[(0,height,.55),(spread*.6,height+.1,.95),(spread,height+.5,1.3),(spread*1.2,height+.48,1.65)],.11 if not horse else .07,white if fox else fur,body)
  if horse:
   for j in range(13):ell('Braided mane',(0,1.2+j*.06,-.34-j*.027),(.065,.09,.12),dark,body)
   ell('Woven saddle blanket',(0,1.58,.1),(.37,.08,.45),mat('Saddle blue',(.12,.23,.3)),body)
   ell('Riding saddle',(0,1.65,.1),(.3,.1,.3),leather(),body)
   for side in [-1,1]:curve('Bridle',[(side*.2,2.15,-.87),(side*.23,1.86,-1.1),(side*.2,1.77,-1.04)],.015,leather(),body)
  if id in ['intro_wolf','dire_wolf','spirit_fox','bristleback']:
   for i in range(26):
    x=random.uniform(-.27,.27);z=random.uniform(-.5,.42);y=height+.29
    mesh('Layered fur tuft',[(x-.05,y,z),(x+.05,y,z),(x+.02,y+.09,z+.18),(x,y+.04,z+.03)],[(0,1,3),(0,3,2),(3,1,2)],white if fox else fur,body)
  if boar:
   for side in [-1,1]:curve('Ivory tusk',[(side*.16,height+.13,-1),(side*.28,height+.22,-1.14),(side*.27,height+.44,-1.09)],.035,ivory,body)
  if dragon or griffin:
   wingmat=mat('Wing membrane',(.25,.16,.12),.05,.75) if dragon else white
   for side in [-1,1]:
    wing=empty('Wing_'+str(side));wing.parent=body
    pts=[(side*.23,1.16,-.2),(side*.9,1.7,.0),(side*1.6,1.8,.55),(side*1.4,1.1,.7),(side*.95,1.05,.6),(side*.4,1.05,.45)]
    mesh('Swept wing',pts,[(0,1,4),(1,2,3,4),(0,4,5)],wingmat,wing)
    for target in [2,3,4]:curve('Wing spar',[pts[0],pts[1],pts[target]],.027,fur,wing)
    if griffin:
     for j in range(9):
      x=side*(.55+j*.11);y=1.25+j*.045;z=.45+j*.025
      ell('Layered flight feather',(x,y,z),(.07,.035,.38),white,wing).rotation_euler[2]=side*.18
   if dragon:
    for j in range(7):beam('Dorsal crest',(0,height+.34,-.4+j*.18),(0,height+.62-j*.02,-.4+j*.18),.07,ivory,body,r2=.001)
  if fox:
   for side in [-1,1]:curve('Spirit marking',[(side*.27,head_y-.04,-.88),(side*.2,head_y+.1,-.97),(side*.1,head_y+.13,-.98)],.013,mat('Spirit jade',(.26,.65,.58),.25,.3),body)
 export(ROOT/'assets/models/companions'/f'{id}.glb')
def hero_variant(outfit):
 reset();bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/vendor/kaykit'/f'{outfit}.glb'))
 arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
 # Reshape the CC0 rig from short/chibi proportions toward a taller storybook adventurer.
 def zmap(z):
  if z<.55:return z*1.7
  if z<1.24:return .935+(z-.55)*1.35
  return 1.8665+(z-1.24)*.56
 for o in list(bpy.data.objects):
  if o.type!='MESH' or not o.name.startswith(outfit+'_'):continue
  # Attached original helmets are resized around their imported local origin separately.
  if o.parent and o.parent.type=='ARMATURE' and o.parent_type=='BONE':
   if 'Helmet' in o.name:o.scale*=.58
   continue
  is_head='Head' in o.name
  for v in o.data.vertices:
   world=o.matrix_world@v.co
   world.z=zmap(world.z)
   if is_head:world.x*=.61;world.y*=.66
   v.co=o.matrix_world.inverted()@world
  for poly in o.data.polygons:poly.use_smooth=True
 bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
 for b in arm.data.edit_bones:
  head=b.head.copy();tail=b.tail.copy();head.z=zmap(head.z);tail.z=zmap(tail.z);b.head=head;b.tail=tail
 bpy.ops.object.mode_set(mode='OBJECT')
 export(ROOT/'assets/models/heroes'/f'{outfit}.glb')
def goblin():
 reset();root=empty('Goblin');body=empty('Body');body.parent=root
 skin=mat('Olive goblin skin',(.13,.22,.075),0,.8);cloth=mat('Road leather',(.17,.11,.065),0,.85);dark=mat('Deep creases',(.025,.03,.018));eye=mat('Goblin amber',(.73,.48,.11),.1,.3)
 parts=[ell('Chest',(0,.94,0),(.28,.34,.18),skin),ell('Waist',(0,.66,0),(.21,.25,.17),skin),ell('Neck',(0,1.22,0),(.13,.22,.13),skin),ell('Goblin skull',(0,1.48,0),(.26,.28,.23),skin),ell('Jaw',(0,1.33,-.12),(.2,.15,.16),skin)]
 fuse(parts,'Lean goblin anatomy',skin,body)
 loft('Leather vest',[(0,.68,.015,.22,.18),(0,.9,.015,.285,.2),(0,1.12,.015,.25,.17)],cloth,body)
 curve('Cross belt',[(-.22,1.1,-.17),(0,.91,-.22),(.2,.72,-.17)],.025,leather(),body)
 ell('Heavy brow',(0,1.54,-.19),(.24,.07,.07),skin,body)
 ell('Long goblin nose',(0,1.42,-.28),(.075,.12,.11),skin,body)
 for side in [-1,1]:
  mesh('Swept pointed ear',[(side*.18,1.56,0),(side*.48,1.72,.06),(side*.3,1.4,.025),(side*.22,1.47,-.08)],[(0,1,3),(1,2,3),(0,2,1),(0,3,2)],skin,body)
  ell('Eye shadow',(side*.12,1.5,-.215),(.07,.045,.04),dark,body)
  ell('Amber eye',(side*.12,1.505,-.245),(.045,.027,.017),eye,body)
  ell('Black pupil',(side*.12,1.505,-.26),(.013,.022,.008),dark,body)
  beam('Fang',(side*.11,1.26,-.235),(side*.12,1.32,-.26),.018,mat('Old ivory',(.67,.59,.4)),body,r2=.001)
  limb=empty('Arm_'+str(side));limb.parent=body;limb.location=coord((side*.28,1.07,0));bpy.context.view_layer.update()
  arm=[beam('Upper arm',(side*.29,1.06,0),(side*.4,.84,-.02),.09,skin),beam('Forearm',(side*.4,.84,-.02),(side*.42,.62,-.1),.07,skin),ell('Hand',(side*.42,.58,-.1),(.08,.1,.08),skin)]
  if side==-1:
   arm.extend([beam('Club shaft',(-.43,.42,-.12),(-.43,1.16,-.12),.035,wood()),ell('Banded club head',(-.43,1.16,-.12),(.12,.18,.12),silver())])
  for o in arm:o.parent=limb;o.matrix_parent_inverse=limb.matrix_world.inverted()
  leg=empty('Leg_'+str(side));leg.parent=body;leg.location=coord((side*.14,.64,0));bpy.context.view_layer.update()
  for o in [beam('Thigh',(side*.14,.62,0),(side*.16,.36,0),.105,cloth),beam('Shin',(side*.16,.36,0),(side*.17,.12,-.02),.065,skin),ell('Boot',(side*.17,.08,-.06),(.085,.08,.15),leather())]:o.parent=leg;o.matrix_parent_inverse=leg.matrix_world.inverted()
 curve('Scowling mouth',[(-.14,1.31,-.245),(0,1.3,-.27),(.14,1.31,-.245)],.009,dark,body)
 export(ROOT/'assets/models/enemies/forest_goblin.glb')
def sanctuary_enemy(kind):
 reset();root=empty(kind);body=empty('Body');body.parent=root
 bark=mat('Ancient bark',(.17,.135,.09),0,.9);moss=mat('Living moss',(.12,.21,.085),0,.95);jade=mat('Heartlight',(.13,.47,.34),.15,.3)
 if kind=='mossling':
  ell('Root bulb',(0,.48,0),(.45,.5,.34),bark,body)
  ell('Moss cap',(0,.85,0),(.5,.24,.38),moss,body)
  for side in [-1,1]:
   curve('Root foot',[(side*.17,.3,0),(side*.27,.09,-.08),(side*.36,.04,-.3)],.08,bark,body)
   curve('Vine arm',[(side*.4,.65,0),(side*.6,.5,-.05),(side*.55,.3,-.12)],.05,moss,body)
   ell('Bright eye',(side*.15,.6,-.32),(.065,.085,.035),jade,body)
  for i in range(7):
   a=i*math.tau/7
   mesh('Crown leaf',[(math.sin(a)*.12,.89,math.cos(a)*.12),(math.sin(a+.5)*.3,1.05,math.cos(a+.5)*.3),(math.sin(a)*.28,1.47,math.cos(a)*.28),(math.sin(a-.5)*.3,1.05,math.cos(a-.5)*.3)],[(0,1,2),(0,2,3)],moss,body)
  ell('Moonleaf bud',(0,1.19,0),(.13,.23,.13),mat('Moonleaf violet',(.35,.17,.39)),body)
 else:
  loft('Gnarled guardian trunk',[(0,.4,0,.5,.35),(0,.95,0,.6,.4),(0,1.7,0,.73,.44),(0,2.35,0,.6,.35),(0,2.7,0,.34,.27)],bark,body,24)
  ell('Brow trunk',(0,2.9,0),(.39,.45,.32),bark,body)
  for i in range(18):
   angle=i*math.tau/18
   curve('Bark grain',[(math.sin(angle)*(.5+.08*math.sin(y*3)),y,math.cos(angle)*(.36+.06*math.sin(y*3))) for y in [.5,.9,1.3,1.7,2.1,2.5]],.015,mat('Bark ridge',(.24,.19,.12)),body)
  for side in [-1,1]:
   arm=empty('Arm_'+str(side));arm.parent=body
   curve('Heavy branch arm',[(side*.5,2.3,0),(side*.95,2.1,0),(side*1.17,1.6,-.1),(side*1.15,1.1,-.18)],.19,bark,arm)
   for finger in range(3):curve('Root fingers',[(side*1.15,1.18,-.18),(side*(1.05+finger*.13),.85,-.3),(side*(1.03+finger*.14),.73,-.4)],.05,bark,arm)
   curve('Root leg',[(side*.3,.75,0),(side*.45,.32,0),(side*.6,.06,-.3)],.22,bark,body)
   for rootindex in range(3):curve('Spreading roots',[(side*.45,.22,0),(side*(.6+rootindex*.18),.05,-.2-rootindex*.15),(side*(.75+rootindex*.2),.03,-.35-rootindex*.15)],.055,bark,body)
   ell('Guardian eye',(side*.15,2.97,-.31),(.09,.055,.04),jade,body)
   for branch in range(3):
    x=side*(.28+branch*.2)
    curve('Antler branch',[(side*.2,3.15,0),(x,3.55,.12),(x+side*.3,3.8+branch*.1,.15)],.05,bark,body)
   for leaf in range(5):ell('Shoulder moss',(side*(.54+leaf*.08),2.3+math.sin(leaf)*.1,.06),(.18,.1,.18),moss,body)
  ell('Living ember',(0,1.78,-.43),(.19,.29,.1),jade,body)
 export(ROOT/'assets/models/enemies'/f'{kind}.glb')
if __name__=='__main__':
 equipment=json.loads((ROOT/'data/equipment.json').read_text())
 for name,e in equipment.items():
  if e['slot']!='Any':gear(name,e)
 for id in ['intro_wolf','dire_wolf','spirit_fox','dragon','griffin','warhorse','golem','bristleback']:creature(id)
 goblin()
 for kind in ['mossling','warden']:sanctuary_enemy(kind)
 for outfit in ['Knight','Rogue','Mage']:hero_variant(outfit)
 print('Original RPG art build complete')

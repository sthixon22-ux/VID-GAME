"""Clothed natural-proportion hero: CC0 MakeHuman head/hands/clothing topology + CC0 KayKit rig.
Run with Blender in background. No uncovered torso/lower-body geometry is exported.
"""
import bpy,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
V=[];UV=[];GROUPS={};group=''
for line in (ROOT/'assets/vendor/makehuman/base.obj.txt').read_text().splitlines():
 if line.startswith('v '):V.append(Vector(tuple(map(float,line.split()[1:4]))))
 elif line.startswith('vt '):UV.append(tuple(map(float,line.split()[1:3])))
 elif line.startswith('g '):group=line[2:].strip()
 elif line.startswith('f '):GROUPS.setdefault(group,[]).append([tuple(int(p)-1 if p else -1 for p in t.split('/')) for t in line.split()[1:]])
SCALE=2.5/(8.491+8.183)
def source(p):return Vector((p.x*SCALE,-p.z*SCALE,(p.y+8.183)*SCALE))
def landmark(name):
 ids={x[0] for f in GROUPS[name] for x in f};return source(sum((V[i] for i in ids),Vector())/len(ids))
def mat(name,c,metal=0,rough=.75):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
 b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*c,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough
 return m
def distance(p,a,b):
 d=b-a;t=max(0,min(1,(p-a).dot(d)/max(.00001,d.length_squared)));return (p-(a+d*t)).length

def build(outfit):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/vendor/kaykit'/f'{outfit}.glb'))
 rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
 for o in list(bpy.data.objects):
  if o.type=='MESH':bpy.data.objects.remove(o,do_unlink=True)
 # Human landmarks supply joint positions. The arms are put into the source rig's T rest pose.
 target={}
 target['root']=Vector((0,0,0));target['hips']=landmark('joint-pelvis')
 target['spine']=target['hips']+Vector((0,0,.22));target['chest']=landmark('joint-neck')-Vector((0,0,.27))
 target['head']=landmark('joint-head')
 for side in ['l','r']:
  shoulder=landmark(f'joint-{side}-shoulder');elbow=landmark(f'joint-{side}-elbow');hand=landmark(f'joint-{side}-hand')
  sign=1 if side=='l' else -1
  target['upperarm.'+side]=shoulder
  target['lowerarm.'+side]=shoulder+Vector((sign*.34,0,0))
  target['wrist.'+side]=shoulder+Vector((sign*.68,0,0))
  target['hand.'+side]=shoulder+Vector((sign*.75,0,0))
  target['handslot.'+side]=shoulder+Vector((sign*.83,0,-.035))
  target['upperleg.'+side]=landmark(f'joint-{side}-upper-leg')
  target['lowerleg.'+side]=landmark(f'joint-{side}-knee')
  target['foot.'+side]=landmark(f'joint-{side}-ankle')
  target['toes.'+side]=landmark(f'joint-{side}-foot-2')
 bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
 old={b.name:(b.head.copy(),b.tail.copy()) for b in rig.data.edit_bones}
 # Preserve bone axes wherever possible; endpoints at adjacent landmarks ensure sensible joints.
 for b in rig.data.edit_bones:
  if b.name not in target:continue
  p=target[b.name];delta=b.tail-b.head;b.head=p;b.tail=p+delta
 for side in ['l','r']:
  chain=['upperarm.','lowerarm.','wrist.','hand.','handslot.']
  for a,b in zip(chain,chain[1:]):rig.data.edit_bones[a+side].tail=target[b+side]
  for a,b in [('upperleg.','lowerleg.'),('lowerleg.','foot.'),('foot.','toes.')]:rig.data.edit_bones[a+side].tail=target[b+side]
 bpy.ops.object.mode_set(mode='OBJECT')
 skin=mat('Skin',(.47,.29,.18),0,.65);cloth=mat('Travel cloth',(.10,.17,.22),0,.92);pants=mat('Trousers',(.065,.085,.09),0,.95);boots=mat('Leather boots',(.06,.035,.02),0,.72);hair=mat('Hair',(.045,.025,.012),0,.8)
 def influence(p):
  # Head and hands use anatomical surfaces. Clothing covers every other body region.
  if p.z>target['head'].z-.16:return [('head',1)]
  side='l' if p.x>0 else 'r'
  sh=landmark(f'joint-{side}-shoulder');el=landmark(f'joint-{side}-elbow');ha=landmark(f'joint-{side}-hand')
  if abs(p.x)>abs(sh.x)*.86 and p.z>target['hips'].z+.05:
   joints=[('upperarm.'+side,sh,el),('lowerarm.'+side,el,ha),('hand.'+side,ha,ha+Vector((.15 if side=='l' else -.15,-.12,0)))]
   nearest=sorted([(distance(p,a,b),name) for name,a,b in joints])[:2]
   weights=[1/max(.015,d)**3 for d,_ in nearest];total=sum(weights)
   return [(name,w/total) for (_,name),w in zip(nearest,weights)]
  if p.z<target['hips'].z-.08:
   hip=target['upperleg.'+side];knee=target['lowerleg.'+side];ankle=target['foot.'+side]
   if p.z<ankle.z+.10:return [('foot.'+side,1)]
   d1=distance(p,hip,knee);d2=distance(p,knee,ankle)
   w1=1/max(.015,d1)**3;w2=1/max(.015,d2)**3
   return [('upperleg.'+side,w1/(w1+w2)),('lowerleg.'+side,w2/(w1+w2))]
  if p.z>target['chest'].z-.12:return [('chest',1)]
  if p.z>target['spine'].z-.05:return [('spine',1)]
  return [('hips',1)]
 def remap(p,weights):
  value=Vector()
  for bone,weight in weights:
   if bone.startswith(('upperarm.','lowerarm.','hand.')):
    side=bone[-1]
    a=landmark(f'joint-{side}-shoulder') if bone.startswith('upperarm') else (landmark(f'joint-{side}-elbow') if bone.startswith('lowerarm') else landmark(f'joint-{side}-hand'))
    b=landmark(f'joint-{side}-elbow') if bone.startswith('upperarm') else landmark(f'joint-{side}-hand')
    if bone.startswith('hand'):b=a+Vector((.15 if side=='l' else -.15,-.12,0))
    d=b-a;new=Vector((1 if side=='l' else -1,0,0));q=d.normalized().rotation_difference(new)
    value+=(target[bone]+q@(p-a))*weight
   else:value+=p*weight
  return value
 def mesh(name,faces,material):
  verts=[];polys=[];weights=[];uvs=[]
  for f in faces:
   poly=[]
   for data in f:
    p=source(V[data[0]]);ws=influence(p);poly.append(len(verts));verts.append(remap(p,ws));weights.append(ws);uvs.append(UV[data[1]] if len(data)>1 and data[1]>=0 else (0,0))
   polys.append(poly)
  if not verts:return None
  data=bpy.data.meshes.new(name);data.from_pydata(verts,[],polys);data.update();o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);o.data.materials.append(material)
  uv=data.uv_layers.new(name='UVMap')
  for poly in data.polygons:
   poly.use_smooth=True
   for li in poly.loop_indices:uv.data[li].uv=uvs[data.loops[li].vertex_index]
  for bone in rig.data.bones:o.vertex_groups.new(name=bone.name)
  for i,ws in enumerate(weights):
   for bone,w in ws:o.vertex_groups[bone].add([i],w,'REPLACE')
  mod=o.modifiers.new('Humanoid skin','ARMATURE');mod.object=rig;o.parent=rig
  return o
 # Body group is used only for the face/neck and hands; the fitted cloth helper supplies the covered body.
 visible=[]
 for f in GROUPS['body']:
  p=sum((source(V[d[0]]) for d in f),Vector())/len(f)
  hand=(abs(p.x)>.6 and p.z>1.3 and p.z<1.9)
  if p.z>2.075 or hand:visible.append(f)
 mesh('Skin',visible,skin)
 regions={'Tunic':[],'Trousers':[],'Boots':[]}
 for f in GROUPS['helper-tights']:
  p=sum((source(V[d[0]]) for d in f),Vector())/len(f)
  regions['Boots' if p.z<.24 else ('Trousers' if p.z<1.25 else 'Tunic')].append(f)
 for name,faces in regions.items():mesh(name,faces,{'Tunic':cloth,'Trousers':pants,'Boots':boots}[name])
 # Eye surfaces follow the head bone; small pupils/catchlights give a readable face.
 def head_ell(name,p,scale,material):
  bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=p)
  o=bpy.context.object;o.name=name;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material)
  for f in o.data.polygons:f.use_smooth=True
  # Apply location into geometry so skinning uses the common rig space.
  bpy.ops.object.transform_apply(location=True,rotation=False,scale=False)
  vg=o.vertex_groups.new(name='head');vg.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Head skin','ARMATURE');mod.object=rig;o.parent=rig
 for side in ['l','r']:
  p=landmark(f'joint-{side}-eye')
  head_ell('Eyes',p,(.033,.033,.026),mat('Eyes white',(.72,.69,.59),0,.2))
  head_ell('Iris',p+Vector((0,-.029,0)),(.014,.005,.014),mat('Iris',(.055,.11,.10),0,.16))
  head_ell('Pupil',p+Vector((0,-.034,0)),(.006,.003,.008),mat('Pupil',(.006,.008,.009),0,.18))
 # A scalp shell with an open face and a swept hairline, rather than pill-shaped bangs.
 head_faces=[]
 for f in GROUPS['helper-hair']:
  p=sum((source(V[d[0]]) for d in f),Vector())/len(f)
  if p.z>2.40 or (p.z>2.22 and p.y>-.045):head_faces.append(f)
 mesh('Hair',head_faces,hair)
 # Preserve the familiar outfit IDs/API and all imported action clips.
 rig.name='Rig'
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/heroes'/f'{outfit}.glb'),export_format='GLB',export_animations=True,export_yup=True,export_apply=True)
for name in ['Knight','Rogue','Mage']:build(name)
print('Natural-proportion clothed heroes built')

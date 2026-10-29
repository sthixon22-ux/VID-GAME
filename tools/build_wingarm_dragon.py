"""CC0 Quaternius dragon derivative: two hind legs + two integrated wing-arms.
Blender 4.3: blender -b -t 2 --python tools/build_wingarm_dragon.py
Source mesh/head/materials retained; old independent wings removed; original
wing membranes, hind-leg anatomy, four-contact rig and motion authored here.
"""
import bpy,bmesh,math,json,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/vendor/quaternius/companions/monsters/Dragon_Evolved.glb'
OUT=ROOT/'assets/models/companions/refined/dragon_wingarm.glb'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
old=next(o for o in bpy.data.objects if o.type=='ARMATURE');old.animation_data_clear();old.data.pose_position='REST'
for action in list(bpy.data.actions):bpy.data.actions.remove(action)
src=next(o for o in bpy.data.objects if o.type=='MESH' and o.vertex_groups)
original_groups={g.index:g.name for g in src.vertex_groups}
body=src.copy();body.data=src.data.copy();bpy.context.collection.objects.link(body);body.name='WingarmDragon_AuthoredBody'
body.parent=None;body.matrix_world=Matrix.Identity(4)
for mod in list(body.modifiers):body.modifiers.remove(mod)
# Delete the old separate back wings, keeping the original arms as the wing arms.
mesh=body.data
remove=[]
weights={}
for v in mesh.vertices:
 dominant=max(v.groups,key=lambda g:g.weight).group if v.groups else 0
 name=original_groups[dominant]
 if any(original_groups[g.group].startswith('Wing') and g.weight>.03 for g in v.groups):remove.append(v.index)
 p=src.matrix_world@v.co
 arm=any(name.startswith(n) for n in ['Shoulder','UpperArm','LowerArm','Middle','Pinky','Index','Thumb'])
 if arm:
  sign=1 if p.x>=0 else -1;distance=max(0,abs(p.x)-.35)
  p.x=sign*(.35+distance*.48);p.z-=distance*.68;p.y-=distance*.2
 elif name.startswith('Body'):
  low=max(0,1.4-p.z);p.y+=low*1.5;p.z=.8+(p.z-.8)*.28
 if p.z>1.8:
  height=p.z-1.8;p.z=1.8+height*.6;p.y-=height*.5
 v.co=p
bm=bmesh.new();bm.from_mesh(mesh);bm.verts.ensure_lookup_table();bmesh.ops.delete(bm,geom=[bm.verts[i] for i in remove],context='VERTS');bm.to_mesh(mesh);bm.free()
# Preserve the remapped original skinning on a clean, correctly scaled rig.
data=bpy.data.armatures.new('FourLimbDragonRig');rig=bpy.data.objects.new('FourLimbDragon',data);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
def bone(name,head,tail,parent=None):
 b=data.edit_bones.new(name);b.head=head;b.tail=tail
 if parent:b.parent=data.edit_bones[parent]
 return b
bone('Root',(0,0,0),(0,0,.25))
bone('Torso',(0,.15,1.4),(0,.1,1.9),'Root');bone('Neck',(0,.1,1.8),(0,-.3,2.04),'Torso');bone('Head',(0,-.3,2.04),(0,-.7,2.4),'Neck')
for i in range(1,5):bone('Tail'+str(i),(0,.5+(i-1)*.4,.95),(0,.5+i*.4,.85),'Torso' if i==1 else 'Tail'+str(i-1))
for side,sign in [('L',1),('R',-1)]:
 bone('UpperWingArm.'+side,(sign*.35,.1,1.6),(sign*.85,-.05,.85),'Torso')
 bone('LowerWingArm.'+side,(sign*.85,-.05,.85),(sign*1.2,-.35,.18),'UpperWingArm.'+side)
 bone('WingHand.'+side,(sign*1.2,-.35,.18),(sign*1.45,-.45,.13),'LowerWingArm.'+side)
 bone('HindThigh.'+side,(sign*.35,.85,1),(sign*.6,.45,.6),'Torso')
 bone('HindShin.'+side,(sign*.6,.45,.6),(sign*.55,1,.3),'HindThigh.'+side)
 bone('HindFoot.'+side,(sign*.55,1,.3),(sign*.6,.45,.1),'HindShin.'+side)
bpy.ops.object.mode_set(mode='OBJECT')
def mapped(name):
 if name=='Root':return 'Root'
 if name in ['Torso','Neck','Head']:return name
 if name.startswith('Body'):return 'Tail'+name[-1]
 if '.' in name:
  side=name.split('.')[-1]
  if name.startswith(('Shoulder','UpperArm')):return 'UpperWingArm.'+side
  if name.startswith('LowerArm'):return 'LowerWingArm.'+side
  return 'WingHand.'+side
 return 'Torso'
# Keep original group weights but merge fingers into the wing wrist.
for group in list(body.vertex_groups):group.name='old_'+group.name
for name in data.bones.keys():body.vertex_groups.new(name=name)
for v in body.data.vertices:
 merged={}
 for g in list(v.groups):
  oldname=original_groups.get(g.group,'Torso');name=mapped(oldname);merged[name]=merged.get(name,0)+g.weight
 for name,weight in merged.items():body.vertex_groups[name].add([v.index],weight,'REPLACE')
for group in list(body.vertex_groups):
 if group.name.startswith('old_'):body.vertex_groups.remove(group)
mod=body.modifiers.new('Four-limb skin','ARMATURE');mod.object=rig;body.parent=rig
# Original anatomy additions use smoothly varying anatomical ring surfaces.
def material(name,color,rough=.65):
 m=bpy.data.materials.new(name);linear=tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in color);m.diffuse_color=(*linear,1);m.use_nodes=True;m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*linear,1);m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=rough;return m
scale=material('WingarmScale',(.09,.26,.29));web=material('WingarmMembrane',(.28,.19,.13));horn=material('WingClawIvory',(.78,.7,.49))
objects=[body,rig]
def obj_mesh(name,verts,faces,mat,groups):
 m=bpy.data.meshes.new(name);m.from_pydata(verts,[],faces);m.update();o=bpy.data.objects.new(name,m);bpy.context.collection.objects.link(o);o.data.materials.append(mat);o.parent=rig
 for n,ids in groups.items():o.vertex_groups.new(name=n).add(ids,1,'REPLACE')
 mod=o.modifiers.new('Skin','ARMATURE');mod.object=rig
 for poly in m.polygons:poly.use_smooth=True
 objects.append(o);return o
def tube(name,points,radii,group,mat):
 verts=[];faces=[];segments=12
 for j,p in enumerate(points):
  for i in range(segments):
   angle=i*math.tau/segments;verts.append((p[0]+math.cos(angle)*radii[j],p[1]+math.sin(angle)*radii[j],p[2]))
 for j in range(len(points)-1):
  for i in range(segments):a=j*segments+i;b=j*segments+(i+1)%segments;faces.append((a,b,b+segments,a+segments))
 faces+=[tuple(reversed(range(segments))),tuple(range((len(points)-1)*segments,len(points)*segments))]
 return obj_mesh(name,verts,faces,mat,{group:list(range(len(verts)))})
for side,s in [('L',1),('R',-1)]:
 tube('MuscularHindThigh.'+side,[(s*.35,.85,1.15),(s*.52,.66,.95),(s*.6,.45,.6)],[.22,.25,.16],'HindThigh.'+side,scale)
 tube('AngledHindShin.'+side,[(s*.6,.45,.6),(s*.57,.82,.4),(s*.55,1,.26)],[.14,.12,.08],'HindShin.'+side,scale)
 tube('GroundedHindFoot.'+side,[(s*.55,.83,.22),(s*.6,.61,.11),(s*.6,.5,.055)],[.15,.19,.14],'HindFoot.'+side,scale)
 for toe in [-1,0,1]:tube('HindClaw.'+side+str(toe),[(s*.6+toe*.12,.45,.12),(s*.6+toe*.13,.22,.07),(s*.6+toe*.13,.13,.045)],[.055,.035,.002],'HindFoot.'+side,horn)
 wrist=(s*1.2,-.35,.22)
 ends=[(s*2.25,.55,.9),(s*2,1.15,.72),(s*1.5,1.65,.64),(s*.3,1.35,.86)]
 boundary=[(s*.4,.2,1.55)]
 for i,end in enumerate(ends):
  if i>0:
   mid=Vector(ends[i-1]).lerp(Vector(end),.5).lerp(Vector(wrist),.18);mid.z-=.07;boundary.append(tuple(mid))
  boundary.append(end)
 verts=[wrist]+boundary;faces=[(0,i,i+1) for i in range(1,len(verts)-1)]
 obj_mesh('IntegratedWingMembrane.'+side,verts,faces,web,{'WingHand.'+side:[0]+list(range(2,len(verts)-1)),'Torso':[1,len(verts)-1]})
 for i,end in enumerate(ends[:-1]):
  mid=tuple((wrist[j]+end[j])*.5 for j in range(3));tube('WingFinger.'+side+str(i),[wrist,mid,end],[.065,.045,.015],'WingHand.'+side,scale)
 # The supporting wrist carries a prominent forward-facing claw, not a separate foreleg.
 tube('WingWristClaw.'+side,[(s*1.18,-.35,.3),(s*1.22,-.55,.35),(s*1.23,-.68,.24)],[.09,.065,.003],'WingHand.'+side,horn)
# Grounded four-contact locomotion plus dedicated flight/breath/impact clips.
rig.animation_data_create();bpy.context.scene.render.fps=24
for clip,duration in [('Idle',48),('Walk',32),('Run',24),('Attack',28),('Support',40),('Guard',40),('Hit',18),('Death',36),('Flight',32)]:
 action=bpy.data.actions.new(clip);rig.animation_data.action=action
 for frame in range(1,duration+1,2):
  t=(frame-1)/(duration-1);wave=math.sin(t*math.tau)
  for pb in rig.pose.bones:pb.rotation_mode='XYZ';pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
  rig.pose.bones['Torso'].rotation_euler.x=.015*wave
  rig.pose.bones['Head'].rotation_euler.z=.025*wave
  if clip in ['Walk','Run']:
   amp=.17 if clip=='Walk' else .28
   for side,phase in [('L',0),('R',math.pi)]:
    stride=math.sin(t*math.tau+phase)
    rig.pose.bones['HindThigh.'+side].rotation_euler.x=stride*amp
    rig.pose.bones['HindShin.'+side].rotation_euler.x=max(0,-stride)*amp
    rig.pose.bones['UpperWingArm.'+side].rotation_euler.x=-stride*amp*.5
    rig.pose.bones['WingHand.'+side].rotation_euler.x=max(0,stride)*amp
  elif clip=='Flight':
   rig.pose.bones['Root'].location.z=.5+.07*wave
   for side,s in [('L',1),('R',-1)]:rig.pose.bones['UpperWingArm.'+side].rotation_euler.y=s*(.35+wave*.35)
  elif clip=='Attack':rig.pose.bones['Neck'].rotation_euler.x=-math.sin(t*math.pi)*.45;rig.pose.bones['Head'].rotation_euler.x=math.sin(t*math.pi)*.2
  elif clip=='Hit':rig.pose.bones['Torso'].rotation_euler.x=math.sin(t*math.pi)*.15
  elif clip=='Death':rig.pose.bones['Root'].rotation_euler.y=t*1.2;rig.pose.bones['Root'].location.z=-t*.3
  elif clip=='Support':rig.pose.bones['Neck'].rotation_euler.x=math.sin(t*math.pi)*.12
  for pb in rig.pose.bones:pb.keyframe_insert('rotation_euler',frame=frame);pb.keyframe_insert('location',frame=frame)
rig.animation_data.action=None
for pb in rig.pose.bones:pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
bpy.ops.object.select_all(action='DESELECT')
for o in objects:o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(OUT),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_apply=False,export_def_bones=True)
manifest={'source':str(SOURCE.relative_to(ROOT)),'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'license':'CC0; existing verified Quaternius source notice retained','output':str(OUT.relative_to(ROOT)),'sha256':hashlib.sha256(OUT.read_bytes()).hexdigest(),'anatomy':'Two hind legs and two integrated supporting wing-arms. No separate back wings or forelegs.','original_work':'Skin remap, hind limbs, wing-arm membranes/fingers/claws, four-contact rig and nine animation clips.'}
(OUT.parent/'DRAGON_WINGARM_SOURCE.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('BUILT_WINGARM_DRAGON',OUT.stat().st_size)

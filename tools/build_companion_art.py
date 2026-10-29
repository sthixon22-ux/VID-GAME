"""Refine licensed Quaternius creature meshes, preserving their native rigs/clips.
Run: blender --background --factory-startup --python tools/build_companion_art.py
The griffin is an original derivative of the CC0 wolf body/rig with new lofted
avian anatomy and feather meshes. Other companions retain artist-authored geometry.
"""
import bpy,bmesh,math,json,random,hashlib,sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
VENDOR=ROOT/'assets/vendor/quaternius/companions'
OUT=ROOT/'assets/models/companions/refined'
TEX=ROOT/'assets/textures/companions'
OUT.mkdir(parents=True,exist_ok=True);TEX.mkdir(parents=True,exist_ok=True)
random.seed(9138)
PALETTES={
 'dire_wolf':{'Main':(.19,.26,.32),'Main_Light':(.58,.65,.65),'Eyes_Black':(.82,.48,.13)},
 'spirit_fox':{'Main':(.65,.70,.80),'Main_Light':(.85,.82,.73),'Grey':(.37,.43,.63),'Eyes':(.18,.64,.80),'Black':(.045,.065,.1)},
 'warhorse':{'Main':(.28,.13,.065),'Main_Dark':(.14,.07,.04),'Main_Light':(.49,.28,.13),'Hair':(.055,.037,.028)},
 'griffin':{'Main':(.56,.32,.12),'Main_Light':(.78,.64,.35),'Nose':(.07,.05,.035),'Eyes_Black':(.85,.51,.12)},
 'dragon':{'Dragon_Main':(.13,.30,.35),'Dragon_Secondary':(.47,.31,.13),'Dragon_Horn':(.80,.75,.57),'Eye_Black':(.82,.52,.13)},
 'golem':{'Granite':(.29,.32,.30),'Jade':(.12,.38,.27),'EyeLight':(.37,.75,.56)}}
SOURCES={'dire_wolf':'animals/Wolf.gltf','spirit_fox':'animals/Fox.gltf','warhorse':'animals/Horse.gltf','griffin':'animals/Wolf.gltf','dragon':'monsters/Dragon_Evolved.glb','golem':'golem/Superhero_Male.glb'}

def texture(name,color,kind):
 path=TEX/(name+'.png')
 img=bpy.data.images.new(name,width=256,height=256,alpha=False)
 pixels=[]
 for y in range(256):
  for x in range(256):
   u=x/256;v=y/256
   broad=math.sin(u*math.tau*3+math.sin(v*math.tau)*.7)*.022+math.sin(v*math.tau*2)*.016
   grain=random.Random(x+y*257+631).uniform(-.012,.012)
   if kind=='scale':
    yy=(v*13)%1;xx=(u*13+(int(v*13)%2)*.5)%1
    ridge=max(0,1-abs(math.sqrt(((xx-.5)*1.3)**2+((yy-.5)*.85)**2)-.46)*22)
    shade=.90+broad+grain-ridge*.055
   elif kind=='stone':
    crack=abs(math.sin(u*21+math.sin(v*19)*2.1)*math.sin(v*23+math.sin(u*15)))
    shade=.90+broad*1.8+grain*2-(.13 if crack<.035 else 0)
   else:
    grainhair=math.sin(u*math.tau*65+math.sin(v*math.tau*6)*.75)
    shade=.94+broad+grain+grainhair*.018
   pixels.extend([max(0,min(1,c*shade)) for c in color]+[1])
 img.pixels=pixels;img.filepath_raw=str(path);img.file_format='PNG';img.save()
 return img

def material(name,color,kind='fur',emission=0):
 mat=bpy.data.materials.new(name);mat.use_nodes=True
 mat.diffuse_color=(*color,1)
 p=mat.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.82 if kind=='fur' else .73
 image=texture(name,color,kind)
 node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=image
 mat.node_tree.links.new(node.outputs['Color'],p.inputs['Base Color'])
 if emission:
  p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
 return mat

def weight(obj,rig,bone):
 obj.parent=rig
 group=obj.vertex_groups.new(name=bone);group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
 mod=obj.modifiers.new('Native creature rig','ARMATURE');mod.object=rig

def mesh_obj(name,verts,faces,mat,rig=None,bone=None):
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);mesh.materials.append(mat)
 for p in mesh.polygons:p.use_smooth=True
 if rig:weight(obj,rig,bone)
 return obj

def loft(name,rings,mat,rig,bone,segments=20):
 # Rings follow the forward Y axis. This is purpose-built avian anatomy.
 verts=[]
 for x,y,z,w,h in rings:
  for k in range(segments):
   a=k*math.tau/segments;verts.append((x+math.cos(a)*w,y,z+math.sin(a)*h))
 faces=[]
 for i in range(len(rings)-1):
  for k in range(segments):
   a=i*segments+k;b=i*segments+(k+1)%segments
   faces.append((a,b,b+segments,a+segments))
 faces.extend([tuple(range(segments-1,-1,-1)),tuple((len(rings)-1)*segments+k for k in range(segments))])
 return mesh_obj(name,verts,faces,mat,rig,bone)

def feather(name,start,end,width,mat,rig,bone):
 start,end=Vector(start),Vector(end);axis=(end-start).normalized();side=axis.cross(Vector((0,0,1))).normalized()
 verts=[];faces=[];rings=12;steps=10
 for i in range(rings):
  t=i/(rings-1);center=start.lerp(end,t);center.z+=math.sin(t*math.pi)*.055
  w=width*(math.sin(math.pi*t)**.7)*(.95-.28*t)+.002
  for k in range(steps):
   a=k*math.tau/steps
   v=center+side*(math.cos(a)*w)+Vector((0,0,math.sin(a)*width*.12))
   verts.append(tuple(v))
 for i in range(rings-1):
  for k in range(steps):
   a=i*steps+k;b=i*steps+(k+1)%steps;faces.append((a,b,b+steps,a+steps))
 faces.extend([tuple(range(steps-1,-1,-1)),tuple((rings-1)*steps+k for k in range(steps))])
 return mesh_obj(name,verts,faces,mat,rig,bone)

def griffin_anatomy(body,rig,mats):
 # Remove the canine head/ears and thick wolf tail; retain the authored quadruped torso/legs.
 bpy.context.view_layer.objects.active=body
 bpy.ops.object.mode_set(mode='EDIT');bm=bmesh.from_edit_mesh(body.data)
 doomed=[v for v in bm.verts if v.co.y<-1.64 or (v.co.y>1.25 and v.co.z>1.35)]
 bmesh.ops.delete(bm,geom=doomed,context='VERTS');bmesh.update_edit_mesh(body.data)
 bpy.ops.object.mode_set(mode='OBJECT')
 ivory=material('griffin_FeatherIvory',(.83,.80,.66))
 dark=material('griffin_FeatherTips',(.27,.22,.15))
 gold=material('griffin_BeakHorn',(.39,.25,.10),'scale')
 eyes=material('griffin_Eyes',(.84,.51,.13),'scale',.25)
 pupils=material('griffin_Pupils',(.015,.02,.023),'scale')
 loft('Avian skull',[ (0,-1.63,2.10,.25,.25),(0,-1.90,2.27,.32,.29),(0,-2.15,2.28,.30,.27),(0,-2.34,2.21,.21,.17)],ivory,rig,'Head')
 loft('Hooked eagle beak',[(0,-2.30,2.23,.17,.12),(0,-2.47,2.20,.145,.10),(0,-2.61,2.12,.075,.08),(0,-2.64,2.02,.008,.014)],gold,rig,'Head')
 for side in [-1,1]:
  # Small inset avian eyes and a swept brow, rather than bulging spherical eyes.
  for label,rad_y,rad_z,x,mat in [('Iris',.072,.048,.296,eyes),('Pupil',.022,.032,.304,pupils)]:
   verts=[(side*x,-2.14,2.38)]
   for k in range(20):
    a=k*math.tau/20;verts.append((side*(x-.006),-2.14+math.cos(a)*rad_y,2.38+math.sin(a)*rad_z))
   faces=[(0,k+1,(k+1)%20+1) for k in range(20)]
   mesh_obj('Avian '+label+str(side),verts,faces,mat,rig,'Head')
  feather('Swept eagle brow',(side*.22,-2.03,2.445),(side*.31,-2.27,2.43),.043,ivory,rig,'Head')
  for k in range(5):
   feather('Swept head crest',(side*(.12+k*.04),-1.94+k*.03,2.49),(side*(.16+k*.06),-1.35+k*.1,2.68-k*.05),.07,ivory,rig,'Head')
  for k in range(5):
   feather('Layered neck plumage',(side*.18,-1.62+k*.045,2.18-k*.09),(side*.41,-1.24+k*.06,1.98-k*.09),.13,ivory,rig,'Neck3')
 bpy.context.view_layer.objects.active=rig;body.select_set(False);rig.select_set(True)
 bpy.ops.object.mode_set(mode='EDIT')
 for side in [-1,1]:
  bone=rig.data.edit_bones.new('Wing.L' if side<0 else 'Wing.R')
  bone.head=(side*.32,-.88,2.05);bone.tail=(side*1.1,-.88,2.05);bone.parent=rig.data.edit_bones['Torso3']
 bpy.ops.object.mode_set(mode='OBJECT')
 for side in [-1,1]:
  bone='Wing.L' if side<0 else 'Wing.R'
  # Overlapping feather fans create a complete feathered wing, not a bat membrane.
  for k in range(10):
   start=(side*(.33+k*.12),-.87+k*.045,2.06+k*.045)
   end=(side*(.83+k*.15),.05+k*.07,2.03+k*.022)
   feather('Primary feather '+bone+str(k),start,end,.13,ivory if k<7 else dark,rig,bone)
  for k in range(8):
   start=(side*(.33+k*.15),-.91+k*.045,2.10+k*.045)
   end=(side*(.58+k*.16),-.30+k*.055,2.15+k*.03)
   feather('Wing coverts '+bone+str(k),start,end,.14,ivory,rig,bone)
 # Thin lion tail, animated by the original tail chain when available.
 tails=[b.name for b in rig.data.bones if 'tail' in b.name.lower()]
 tailbone=tails[0] if tails else 'Torso'
 loft('Lion tail',[(0,1.05,1.72,.085,.085),(0,1.65,1.68,.073,.073),(0,2.15,1.93,.06,.06),(0,2.55,2.08,.055,.055)],mats[0],rig,tailbone,12)
 for k in range(5):feather('Tail tuft',(0,2.35,2.05),((k-2)*.06,2.85,2.15+(k%2)*.04),.085,dark,rig,tailbone)
 # Add hand-keyed wing layers to each licensed native body action.
 for action in bpy.data.actions:
  rig.animation_data.action=action
  start,end=action.frame_range
  for side in [-1,1]:
   bone=rig.pose.bones['Wing.L' if side<0 else 'Wing.R'];bone.rotation_mode='XYZ'
   for k in range(9):
    t=k/8;frame=start+(end-start)*t
    amp=.16 if 'Idle' in action.name else (.32 if 'Attack' in action.name else .23)
    bone.rotation_euler=(side*(.22+math.sin(t*math.tau)*amp),0,side*.08)
    bone.keyframe_insert('rotation_euler',frame=frame,group=bone.name)
 rig.animation_data.action=None

def stone_guardian(rel):
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(VENDOR/rel))
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 rig.data.pose_position='REST'
 stone=material('golem_Granite',PALETTES['golem']['Granite'],'stone')
 crystal=material('golem_Jade',PALETTES['golem']['Jade'],'stone',.18)
 eye=material('golem_EyeLight',PALETTES['golem']['EyeLight'],'stone',.35)
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
 for mesh in meshes:
  for index,mat in enumerate(list(mesh.data.materials)):
   mesh.data.materials[index]=eye if 'Eyes' in mat.name else stone
  if any('Superhero' in m.name or 'Granite' in m.name for m in mesh.data.materials):
   for v in mesh.data.vertices:v.co+=v.normal*.008
  for face in mesh.data.polygons:face.use_smooth=True
 def shard(name,center,size,bone,mat):
  center=Vector(center);verts=[];steps=7
  for ring,(height,radius) in enumerate([(-.55,.65),(-.12,1),(.38,.72),(.9,.06)]):
   for k in range(steps):
    a=k*math.tau/steps+.17*(ring%2)
    verts.append(tuple(center+Vector((math.cos(a)*size[0]*radius,math.sin(a)*size[1]*radius,height*size[2]))))
  faces=[]
  for ring in range(3):
   for k in range(steps):
    a=ring*steps+k;b=ring*steps+(k+1)%steps;faces.append((a,b,b+steps,a+steps))
  faces.extend([tuple(range(steps-1,-1,-1)),tuple(3*steps+k for k in range(steps))])
  obj=mesh_obj(name,verts,faces,mat,rig,bone)
  for face in obj.data.polygons:face.use_smooth=False
 def panel(name,outline,depth,bone,mat):
  verts=[(x,y,z) for x,y,z in outline]+[(x,y+depth,z) for x,y,z in outline]
  n=len(outline);faces=[tuple(range(n-1,-1,-1)),tuple(n+i for i in range(n))]
  for i in range(n):faces.append((i,(i+1)%n,(i+1)%n+n,i+n))
  return mesh_obj(name,verts,faces,mat,rig,bone)
 # Carved stone armor gives the guardian a construct silhouette and covers the base anatomy.
 chest=rig.data.bones['spine_03'].head_local
 z=chest.z
 panel('Carved breastplate',[(-.28,-.18,z+.17),(.28,-.18,z+.17),(.31,-.20,z-.04),(.19,-.22,z-.29),(-.19,-.22,z-.29),(-.31,-.20,z-.04)],.065,'spine_03',stone)
 shard('Heartstone',(0,-.24,z-.04),(.055,.035,.10),'spine_03',crystal)
 hips=rig.data.bones['pelvis'].head_local.z
 panel('Granite hip guard',[(-.24,-.14,hips+.06),(.24,-.14,hips+.06),(.29,-.18,hips-.16),(.18,-.20,hips-.27),(-.18,-.20,hips-.27),(-.29,-.18,hips-.16)],.055,'pelvis',stone)
 head=rig.data.bones['Head'].head_local
 panel('Chiseled face mask',[(-.105,-.145,head.z+.24),(.105,-.145,head.z+.24),(.13,-.16,head.z+.12),(.085,-.18,head.z-.04),(0,-.19,head.z-.09),(-.085,-.18,head.z-.04),(-.13,-.16,head.z+.12)],.055,'Head',stone)
 for sign in [-1,1]:
  x=sign*.055
  panel('Jade eye slit '+str(sign),[(x-.031,-.193,head.z+.125),(x+.031,-.193,head.z+.125),(x+.026,-.194,head.z+.10),(x-.026,-.194,head.z+.10)],.008,'Head',eye)
 for side in ['l','r']:
  sign=1 if side=='l' else -1
  for label,bone_name,size in [('Shoulder','upperarm_'+side,(.145,.13,.21)),('Forearm','lowerarm_'+side,(.11,.10,.15)),('Knee','calf_'+side,(.1,.09,.15))]:
   bone=rig.data.bones.get(bone_name)
   if bone is None:continue
   center=bone.head_local.copy();center.z+=.025
   shard('Granite '+label+side,center,size,bone_name,stone)
   offset=Vector((sign*.035,-.015,.07))
   shard('Jade inset '+label+side,center+offset,tuple(x*.4 for x in size),bone_name,crystal)
  foot=rig.data.bones.get('foot_'+side)
  if foot:
   x=foot.head_local.x
   loft('Stone boot '+side,[(x,.11,.115,.085,.065),(x,-.08,.12,.115,.08),(x,-.26,.095,.095,.065)],stone,rig,'foot_'+side,8)
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
 bpy.ops.object.select_all(action='DESELECT')
 for mesh in meshes:mesh.select_set(True)
 bpy.context.view_layer.objects.active=meshes[0]
 bpy.ops.object.join()
 for mesh in [o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]:
  bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
  bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
 for mesh in [o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]:mesh.select_set(True)
 rig.data.pose_position='POSE'
 bpy.context.view_layer.objects.active=rig
 path=OUT/'golem.glb'
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_apply=False,export_def_bones=True)
 print('BUILT_COMPANION golem',path.stat().st_size,flush=True)

def refine(id,rel):
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(VENDOR/rel))
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 rig.data.pose_position='REST'
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
 # Importer display-only Icosphere bone shapes are not selected/exported.
 materials=[]
 for mesh in meshes:
  for i,original in enumerate(list(mesh.data.materials)):
   name=original.name.split('.')[0]
   p=original.node_tree.nodes.get('Principled BSDF') if original.use_nodes else None
   base=tuple(p.inputs['Base Color'].default_value[:3]) if p else tuple(original.diffuse_color[:3])
   color=PALETTES[id].get(name,base)
   kind='stone' if id=='golem' else ('scale' if id=='dragon' else 'fur')
   glow=.22 if (id in ['spirit_fox','golem'] and ('Eye' in name or 'Secondary' in name)) else 0
   mat=material(id+'_'+name,color,kind,glow)
   mesh.data.materials[i]=mat;materials.append(mat)
  if id=='griffin':griffin_anatomy(mesh,rig,materials)
  # Weld split flat-shaded corners before subdivision; retain original skin groups.
  bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
  bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
  bpy.ops.mesh.remove_doubles(threshold=.00008)
  bpy.ops.mesh.tris_convert_to_quads(face_threshold=.6,shape_threshold=.6)
  bpy.ops.object.mode_set(mode='OBJECT')
  sub=mesh.modifiers.new('Soft authored contours','SUBSURF');sub.levels=1;sub.render_levels=1
  # Apply refinement in rest pose, preserving armature and weights.
  bpy.ops.object.modifier_apply(modifier=sub.name)
  for p in mesh.data.polygons:p.use_smooth=True
 if id=='griffin':
  meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
  bpy.ops.object.select_all(action='DESELECT')
  for mesh in meshes:mesh.select_set(True)
  bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join()
 # Give new and imported meshes proper UVs for painted surface detail.
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
 for mesh in meshes:
  bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
  bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
  # Painted underside shading uses static vertex colors (deforms with the skin).
  attr=mesh.data.color_attributes.new(name='PaintedShade',type='FLOAT_COLOR',domain='CORNER')
  zmin=min(v.co.z for v in mesh.data.vertices);zmax=max(v.co.z for v in mesh.data.vertices)
  for loop in mesh.data.loops:
   v=mesh.data.vertices[loop.vertex_index];t=(v.co.z-zmin)/max(.01,zmax-zmin)
   shade=.82+.18*t;attr.data[loop.index].color=(shade,shade,shade,1)
  mesh.data.color_attributes.active_color=attr
 rig.data.pose_position='POSE'
 bpy.context.scene.frame_set(0)
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
 for mesh in meshes:mesh.select_set(True)
 bpy.context.view_layer.objects.active=rig
 # Clean source suffixes: Godot gets stable native clip names.
 for action in bpy.data.actions:
  action.name=action.name.replace('_AnimalArmature','').replace('_CharacterArmature','').replace('CharacterArmature|','')
 path=OUT/(id+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_apply=False,export_def_bones=True)
 if id=='griffin':
  for image in bpy.data.images:
   if image.source=='FILE':image.pack()
  bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'assets/art_sources/griffin.blend'))
 print('BUILT_COMPANION',id,path.stat().st_size,flush=True)

requested=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else list(SOURCES)
for id in requested:
 if id=='golem':stone_guardian(SOURCES[id])
 elif id=='dragon':
  import subprocess
  subprocess.run([bpy.app.binary_path,'-b','-t','2','--python',str(ROOT/'tools/build_wingarm_dragon.py')],check=True)
 else:refine(id,SOURCES[id])
manifest={}
for id,rel in SOURCES.items():
 native=False
 path=OUT/('dragon_wingarm.glb' if id=='dragon' else id+'.glb')
 manifest[id]={'source':rel,'runtime_model':str(path.relative_to(ROOT)),'geometry':'Four-limbed wing-arm derivative; see DRAGON_WINGARM_SOURCE.json' if id=='dragon' else ('Original stone-guardian derivative of licensed humanoid base' if id=='golem' else ('Original avian anatomy/wing layer on licensed quadruped' if id=='griffin' else 'Refined licensed animal geometry and painted materials')),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

(OUT/'DERIVATIVES.json').write_text(json.dumps(manifest,indent=2)+'\n')

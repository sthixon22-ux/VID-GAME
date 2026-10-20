class_name Art
extends RefCounted
static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var mesh=MeshInstance3D.new()
 var shape=BoxMesh.new()
 shape.size=size
 mesh.mesh=shape
 mesh.position=pos
 var material=StandardMaterial3D.new()
 material.albedo_color=color
 mesh.material_override=material
 parent.add_child(mesh)
 return mesh
static func shape(parent: Node3D, pos: Vector3, scale_: Vector3, color: Color, kind: String="sphere") -> MeshInstance3D:
 var mesh=MeshInstance3D.new()
 if kind=="cone":
  var cone=CylinderMesh.new()
  cone.top_radius=0.0
  cone.bottom_radius=0.5
  cone.height=1.0
  cone.radial_segments=7
  mesh.mesh=cone
 elif kind=="cylinder":
  var cylinder=CylinderMesh.new()
  cylinder.top_radius=0.5
  cylinder.bottom_radius=0.5
  cylinder.height=1.0
  cylinder.radial_segments=8
  mesh.mesh=cylinder
 else:
  var sphere=SphereMesh.new()
  sphere.radial_segments=10
  sphere.rings=5
  mesh.mesh=sphere
 mesh.position=pos
 mesh.scale=scale_
 var material=StandardMaterial3D.new()
 material.albedo_color=color
 material.roughness=0.85
 mesh.material_override=material
 parent.add_child(mesh)
 return mesh
static func actor(kind: String, gear: Dictionary={}) -> Node3D:
 if kind=="Hero": return load("res://scripts/hero_visual.gd").new(gear,State.hero.get("profile",{}))
 if kind=="Mira":
  var npc=load("res://scripts/hero_visual.gd").new({"Chest":"Leather Vest","Weapon":"Iron Sword","Shield":"None"})
  npc.find_child("EquippedWeapon",true,false).hide()
  return npc
 if kind=="Warden": return warden()
 if kind=="Mossling": return mossling()
 var root=Node3D.new()
 var body=Node3D.new()
 body.name="Body"
 root.add_child(body)
 if kind=="Wolf":
  shape(body,Vector3(0,0.65,0),Vector3(0.65,0.65,1.25),Color("798ba0"))
  shape(body,Vector3(0,0.95,-0.58),Vector3(0.52,0.55,0.55),Color("a1b3c4"))
  shape(body,Vector3(0,0.8,-0.9),Vector3(0.32,0.25,0.45),Color("d7e0df"))
  for x in [-0.19,0.19]:
   shape(body,Vector3(x,1.26,-0.57),Vector3(0.2,0.4,0.22),Color("617487"),"cone")
   shape(body,Vector3(x,0.99,-0.81),Vector3(0.07,0.08,0.04),Color("f8d878"))
   for z in [-0.35,0.35]:
    shape(body,Vector3(x,0.27,z),Vector3(0.17,0.55,0.18),Color("738499"),"cylinder").name="Leg_%s_%s" % [x,z]
  var tail=shape(body,Vector3(0,0.8,0.75),Vector3(0.25,0.3,0.8),Color("a1b3c4"))
  tail.rotation.x=-0.5
 else:
  var goblin=kind=="Goblin"
  var villager=kind=="Mira"
  var skin=Color("83ad50") if goblin else Color("edbd91")
  var armor=Color("794e3a") if goblin else (Color("7798b4") if gear.get("Chest")=="Steel Cuirass" else Color("647944"))
  if villager: armor=Color("719174")
  var cloak=box(body,Vector3(0,0.97,0.22),Vector3(0.62,1.0,0.08),Color("773e50"))
  cloak.rotation.x=-0.12
  if villager:
   cloak.material_override=surface(Color("bda17c"),"fabric")
   shape(body,Vector3(0,0.64,0),Vector3(0.8,0.7,0.6),Color("66816b"),"cone")
  shape(body,Vector3(0,1.02,0),Vector3(0.77,0.86,0.48),armor)
  box(body,Vector3(0,0.73,-0.01),Vector3(0.66,0.13,0.46),Color("674633"))
  box(body,Vector3(0,0.73,-0.26),Vector3(0.15,0.14,0.05),Color("d9b766"))
  shape(body,Vector3(0,1.69,0),Vector3(0.58,0.61,0.52),skin)
  shape(body,Vector3(0,1.92,0.06),Vector3(0.61,0.3,0.53),Color("334334") if goblin else Color("684734"))
  for x in [-1,1]:
   box(body,Vector3(x*0.13,1.72,-0.255),Vector3(0.08,0.1,0.035),Color("282d36"))
   shape(body,Vector3(x*0.44,1.16,0),Vector3(0.27,0.35,0.37),armor)
   shape(body,Vector3(x*0.46,0.89,0),Vector3(0.21,0.43,0.23),skin,"cylinder").name="Arm_%s" % x
   shape(body,Vector3(x*0.19,0.36,0),Vector3(0.24,0.65,0.27),Color("394b60"),"cylinder").name="Leg_%s" % x
   box(body,Vector3(x*0.19,0.12,-0.08),Vector3(0.27,0.24,0.42),Color("473f3b"))
   if goblin:
    var ear=shape(body,Vector3(x*0.35,1.75,0),Vector3(0.25,0.45,0.18),skin,"cone")
    ear.rotation.z=x*-0.9
  if goblin:
   shape(body,Vector3(-0.57,0.9,-0.15),Vector3(0.13,0.85,0.13),Color("654532"),"cylinder")
   shape(body,Vector3(-0.57,1.45,-0.15),Vector3(0.32,0.45,0.32),Color("635e60"))
  elif not villager:
   box(body,Vector3(-0.58,1.18,-0.12),Vector3(0.12,0.93,0.06),Color("d8e7ec") if gear.get("Weapon")=="Iron Sword" else Color("ffe49b"))
   box(body,Vector3(-0.58,0.74,-0.12),Vector3(0.38,0.07,0.12),Color("d9b766"))
   if gear.get("Shield","None")!="None":
    shape(body,Vector3(0.57,1,-0.12),Vector3(0.58,0.73,0.14),Color("d9b766"))
    shape(body,Vector3(0.57,1,-0.22),Vector3(0.45,0.6,0.07),Color("395d7c"))
    box(body,Vector3(0.57,1,-0.27),Vector3(0.07,0.37,0.03),Color("e8ce8c"))
 return root
static func tree(root: Node3D, pos: Vector3, size_: float=1.0):
 var tree_=Node3D.new()
 root.add_child(tree_)
 tree_.position=pos
 tree_.scale=Vector3.ONE*size_
 CameraObstacles.box(tree_,Vector3(0,1.7,0),Vector3(0.8,3.4,0.8))
 CameraObstacles.sphere(tree_,Vector3(0,4,0),1.7)
 shape(tree_,Vector3(0,1.7,0),Vector3(0.65,3.4,0.65),Color("68513b"),"cylinder").material_override=surface(Color("9c8264"),"wood",2)
 for side in [-1,1]:
  var branch=shape(tree_,Vector3(side*0.4,2.6,0),Vector3(0.25,1.5,0.25),Color("68513b"),"cylinder")
  branch.rotation.z=side*-0.65
  branch.material_override=surface(Color("9c8264"),"wood",1)
 for i in range(3):
  var canopy=shape(tree_,Vector3(sin(i*2.3)*0.65,3.4+i*0.65,cos(i*2.3)*0.55),Vector3(3.1-i*0.45,2.4,3.0-i*0.4),Color("47794e").lightened(i*0.045))
  canopy.material_override=foliage()
static func sign_(root: Node3D, pos: Vector3, text_: String) -> Label3D:
 var label=Label3D.new()
 root.add_child(label)
 label.position=pos
 label.text=text_
 label.font_size=28
 label.pixel_size=0.0065
 label.visibility_range_end=22
 label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 label.modulate=Color("fff0ca")
 label.outline_size=8
 return label
static func environment_(root: Node3D):
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-48,-28,0)
 light.light_color=Color("fff0d4")
 light.light_energy=0.85
 light.shadow_enabled=true
 root.add_child(light)
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_SKY
 var sky=Sky.new()
 var sky_material=ProceduralSkyMaterial.new()
 sky_material.sky_top_color=Color("649fb8")
 sky_material.sky_horizon_color=Color("d6e4c5")
 sky_material.ground_horizon_color=Color("d6e4c5")
 sky.sky_material=sky_material
 env.environment.sky=sky
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color("c3d5db")
 env.environment.ambient_light_energy=0.4
 env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 env.environment.tonemap_exposure=0.8
 root.add_child(env)
 box(root,Vector3(0,-0.25,0),Vector3(100,0.4,100),Color("537a43")).material_override=surface(Color("7b995d"),"grass",35)

static var materials: Dictionary={}
static func surface(color: Color, texture_: String, tiles: float=1.0) -> StandardMaterial3D:
 var key="%s_%s_%s" % [color.to_html(),texture_,tiles]
 if materials.has(key): return materials[key]
 var mat=StandardMaterial3D.new()
 mat.albedo_color=color
 var mapped={"stone":"T_UnevenBrick","wood":"T_WoodTrim","tile":"T_RoundTiles","metal":"T_MetalOrnaments","plaster":"T_Plaster"}.get(texture_,"")
 if mapped!="":
  mat.albedo_texture=load("res://assets/vendor/quaternius_village/%s_BaseColor.png" % mapped)
  var normal_path="res://assets/vendor/quaternius_village/%s_Normal.png" % mapped
  if ResourceLoader.exists(normal_path):
   mat.normal_enabled=true
   mat.normal_texture=load(normal_path)
  var roughness_path="res://assets/vendor/quaternius_village/%s_Roughness.png" % mapped
  if ResourceLoader.exists(roughness_path): mat.roughness_texture=load(roughness_path)
 else: mat.albedo_texture=load("res://assets/textures/%s.png" % texture_)
 mat.uv1_scale=Vector3(tiles,tiles,tiles)
 mat.roughness=0.9
 if texture_=="wood":
  # Sample the wood-grain strip of the pack's trim atlas, not its stone/end-grain rows.
  mat.uv1_scale=Vector3(1,0.28,1)
  mat.uv1_offset=Vector3(0,0.015,0)
 if texture_=="plaster":
  mat.roughness_texture=load("res://assets/vendor/quaternius_village/T_Plaster_ORM.png")
  mat.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
 materials[key]=mat
 return mat
static func mossling() -> Node3D:
 var root=Node3D.new()
 var body=Node3D.new()
 body.name="Body"
 root.add_child(body)
 shape(body,Vector3(0,0.55,0),Vector3(1.3,1.1,1.1),Color("79ab70"))
 for x in [-0.2,0.2]:
  shape(body,Vector3(x,0.72,-0.5),Vector3(0.13,0.17,0.08),Color("263e43"))
  shape(body,Vector3(x*2,1.15,0),Vector3(0.4,0.7,0.3),Color("9cbd73"),"cone")
 shape(body,Vector3(0,1.3,0),Vector3(0.35,0.5,0.35),Color("c798c5"),"cone")
 return root
static func warden() -> Node3D:
 var root=Node3D.new()
 var body=Node3D.new()
 body.name="Body"
 root.add_child(body)
 shape(body,Vector3(0,1.4,0),Vector3(1.6,2.4,1.1),Color("77735a"),"cylinder").material_override=surface(Color("a19775"),"wood",2)
 shape(body,Vector3(0,2.8,0),Vector3(1.3,1.3,0.9),Color("807c5d"))
 for side in [-1,1]:
  var arm=shape(body,Vector3(side*1.2,1.5,0),Vector3(0.5,2.0,0.55),Color("756c52"),"cylinder")
  arm.rotation.z=side*0.3
  arm.name="Arm_%s" % side
  shape(body,Vector3(side*0.5,0.35,0),Vector3(0.65,0.7,0.65),Color("706c54"),"cylinder")
  shape(body,Vector3(side*0.3,2.9,-0.46),Vector3(0.18,0.16,0.07),Color("b4ebc8"))
  for i in range(3):
   var branch=shape(body,Vector3(side*(0.45+i*0.25),3.45+i*0.25,0),Vector3(0.25,1.2,0.25),Color("888263"),"cone")
   branch.rotation.z=side*(0.4+i*0.3)
  shape(body,Vector3(side*0.85,2.0,0.2),Vector3(1.0,0.7,0.9),Color("688b62"))
 var heart=shape(body,Vector3(0,1.65,-0.6),Vector3(0.5,0.7,0.18),Color("99dfbe"),"cone")
 var glow=OmniLight3D.new()
 heart.add_child(glow)
 glow.light_color=Color("8dedc6")
 glow.omni_range=3
 glow.light_energy=1.2
 return root
static func animate(model: Node3D, time_: float, moving: bool):
 if model.has_method("motion"):
  model.motion(moving,Input.is_physical_key_pressed(KEY_SHIFT))
  return
 var body=model.get_node_or_null("Body")
 if not body: return
 body.position.y=absf(sin(time_*9))*0.08 if moving else sin(time_*2)*0.025
 body.rotation.z=sin(time_*9)*0.035 if moving else 0.0
 var index=0
 for child in body.get_children():
  if str(child.name).begins_with("Leg_") or str(child.name).begins_with("Arm_"):
   child.rotation.x=sin(time_*9+index*PI)*0.4 if moving else sin(time_*2+index)*0.035
   index+=1

static var leaf_material: ShaderMaterial
static func foliage() -> ShaderMaterial:
 if leaf_material==null:
  leaf_material=ShaderMaterial.new()
  leaf_material.shader=load("res://assets/shaders/leaves.gdshader")
 return leaf_material

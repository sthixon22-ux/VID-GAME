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
  cone.radial_segments=16
  mesh.mesh=cone
 elif kind=="cylinder":
  var cylinder=CylinderMesh.new()
  cylinder.top_radius=0.5
  cylinder.bottom_radius=0.5
  cylinder.height=1.0
  cylinder.radial_segments=20
  mesh.mesh=cylinder
 else:
  var sphere=SphereMesh.new()
  sphere.radial_segments=24
  sphere.rings=12
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
 if kind=="Goblin": return CompanionVisual.model("res://assets/models/enemies/forest_goblin.glb")
 if kind=="Wolf": return CompanionVisual.build("intro_wolf")
 if kind=="Bristleback": return CompanionVisual.build("bristleback")
 if kind=="Hero":
  var appearance:Dictionary=State.hero.get("profile",{}).duplicate(true)
  appearance["class"]=State.hero.primary
  return load("res://scripts/hero_visual.gd").new(gear,appearance)
 if kind=="Mira":
  var npc=load("res://scripts/hero_visual.gd").new({"Chest":"Leather Vest","Weapon":"Iron Sword","Shield":"None"},{"class":"Healer","sex":"Female"})
  npc.find_child("EquippedWeapon",true,false).hide()
  return npc
 if kind=="Warden": return warden()
 if kind=="Mossling": return mossling()
 return Node3D.new()
static func tree(root:Node3D,pos:Vector3,size_:float=1.0):
 var tree_=Node3D.new()
 root.add_child(tree_)
 tree_.position=pos
 tree_.scale=Vector3.ONE*size_
 CameraObstacles.box(tree_,Vector3(0,2.5,0),Vector3(0.7,5,0.7))
 var trunk=shape(tree_,Vector3(0,2.3,0),Vector3(0.55,4.6,0.55),Color("685b48"),"cylinder")
 trunk.mesh.top_radius=0.32
 trunk.material_override=surface(Color("8e816a"),"wood",3)
 for i in range(5):
  var angle=i*2.4
  var branch=shape(tree_,Vector3(sin(angle)*0.5,3.4+i*.22,cos(angle)*0.5),Vector3(0.2,2.5,0.2),Color("625843"),"cylinder")
  branch.rotation=Vector3(cos(angle)*.55,0,sin(angle)*.55)
  branch.material_override=surface(Color("968970"),"wood",2)
 var cards=MultiMeshInstance3D.new()
 var multi=MultiMesh.new()
 multi.transform_format=MultiMesh.TRANSFORM_3D
 var quad=QuadMesh.new()
 quad.size=Vector2(2.6,2.1)
 multi.mesh=quad
 multi.instance_count=40
 var rng=RandomNumberGenerator.new()
 rng.seed=int(absf(pos.x*137+pos.z*331))+55
 for i in range(40):
  var point=Vector3(rng.randf_range(-2,2),rng.randf_range(3.5,6.5),rng.randf_range(-2,2))
  var angles=Vector3(rng.randf_range(-.9,.9),rng.randf_range(0,TAU),rng.randf_range(-.7,.7))
  multi.set_instance_transform(i,Transform3D(Basis.from_euler(angles),point))
 cards.multimesh=multi
 cards.material_override=foliage()
 tree_.add_child(cards)
static func sign_(root: Node3D, pos: Vector3, text_: String) -> Label3D:
 var label=Label3D.new()
 root.add_child(label)
 label.position=pos
 label.text=text_
 label.font_size=22
 label.pixel_size=0.0065
 label.visibility_range_end=10
 label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 label.modulate=Color("fff0ca")
 label.outline_size=5
 return label
static func environment_(root: Node3D):
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-48,-28,0)
 light.light_color=Color("fff0d4")
 light.light_energy=1.05
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
 env.environment.tonemap_exposure=1.0
 env.environment.adjustment_enabled=true
 env.environment.adjustment_saturation=0.85
 root.add_child(env)
 box(root,Vector3(0,-0.25,0),Vector3(240,0.4,240),Color("537a43")).material_override=surface(Color("d4d5b6"),"grass",95)

static var materials: Dictionary={}
static func surface(color: Color, texture_: String, tiles: float=1.0) -> StandardMaterial3D:
 var key="%s_%s_%s" % [color.to_html(),texture_,tiles]
 if materials.has(key): return materials[key]
 var mat=StandardMaterial3D.new()
 mat.albedo_color=color
 var mapped={"stone":"T_UnevenBrick","wood":"T_WoodTrim","tile":"T_RoundTiles","metal":"T_MetalOrnaments","plaster":"T_Plaster"}.get(texture_,"")
 if texture_ in ["grass","dirt","fabric"]:
  var surface_name="cloth" if texture_=="fabric" else texture_
  mat.albedo_texture=load("res://assets/textures/rpg/%s_albedo.png" % surface_name)
  mat.normal_enabled=true
  mat.normal_texture=load("res://assets/textures/rpg/%s_normal.png" % surface_name)
  mat.normal_scale=0.45
  mat.roughness_texture=load("res://assets/textures/rpg/%s_roughness.png" % surface_name)
 elif mapped!="":
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
static func mossling()->Node3D:
 return CompanionVisual.model("res://assets/models/enemies/mossling.glb")
static func warden()->Node3D:
 var model=CompanionVisual.model("res://assets/models/enemies/warden.glb")
 var glow=OmniLight3D.new()
 glow.position=Vector3(0,1.8,-.5)
 glow.light_color=Color("8dedc6")
 glow.omni_range=3
 glow.light_energy=.8
 model.add_child(glow)
 return model
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
  if str(child.name).begins_with("Wing_"): child.rotation.z=sin(time_*2)*.08
  if str(child.name).begins_with("Leg_") or str(child.name).begins_with("Arm_"):
   child.rotation.x=sin(time_*9+index*PI)*0.4 if moving else sin(time_*2+index)*0.035
   index+=1

static var leaf_material: ShaderMaterial
static func foliage() -> ShaderMaterial:
 if leaf_material==null:
  leaf_material=ShaderMaterial.new()
  leaf_material.shader=load("res://assets/shaders/leaves.gdshader")
  leaf_material.set_shader_parameter("canopy",load("res://assets/textures/rpg/canopy.png"))
 return leaf_material

static func studio(root:Node3D):
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color("172535")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color("b8c8d6")
 env.environment.ambient_light_energy=0.45
 root.add_child(env)
 var key=DirectionalLight3D.new()
 key.rotation_degrees=Vector3(-35,-25,0)
 key.light_energy=1.1
 key.shadow_enabled=true
 root.add_child(key)
 var fill=OmniLight3D.new()
 fill.position=Vector3(2,2,2)
 fill.light_color=Color("c7dbed")
 fill.light_energy=0.7
 root.add_child(fill)
 shape(root,Vector3(0,-.04,0),Vector3(3.2,.08,3.2),Color("243442"),"cylinder")

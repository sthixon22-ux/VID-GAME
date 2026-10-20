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
static func actor(kind: String, gear: Dictionary={}) -> Node3D:
 var root=Node3D.new()
 if kind=="Wolf":
  box(root,Vector3(0,0.5,0),Vector3(0.6,0.6,1.1),Color.SLATE_GRAY)
  box(root,Vector3(0,0.8,-0.6),Vector3(0.5,0.5,0.5),Color.LIGHT_SLATE_GRAY)
  for x in [-0.2,0.2]:
   for z in [-0.35,0.35]: box(root,Vector3(x,0.2,z),Vector3(0.15,0.4,0.15),Color.SLATE_GRAY)
 else:
  var goblin=kind=="Goblin"
  var chest=Color.SADDLE_BROWN if goblin else (Color.STEEL_BLUE if gear.get("Chest","")=="Steel Cuirass" else Color.DARK_OLIVE_GREEN)
  box(root,Vector3(0,0.95,0),Vector3(0.65,0.8,0.4),chest)
  box(root,Vector3(0,1.6,0),Vector3(0.48,0.48,0.45),Color.YELLOW_GREEN if goblin else Color.BISQUE)
  for x in [-0.2,0.2]: box(root,Vector3(x,0.3,0),Vector3(0.25,0.6,0.3),Color.DARK_SLATE_GRAY)
  if goblin:
   box(root,Vector3(-0.6,0.9,0),Vector3(0.18,0.9,0.18),Color.SADDLE_BROWN)
  else:
   box(root,Vector3(-0.55,1,0),Vector3(0.12,1.15,0.15),Color.SILVER if gear.get("Weapon")=="Iron Sword" else Color.GOLD)
   if gear.get("Shield","None")!="None": box(root,Vector3(0.55,0.95,0),Vector3(0.4,0.65,0.15),Color.PERU)
 return root
static func environment_(root: Node3D):
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-55,-30,0)
 light.light_energy=1.3
 root.add_child(light)
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color(0.25,0.4,0.45)
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color(0.7,0.8,0.85)
 env.environment.ambient_light_energy=0.7
 root.add_child(env)
 box(root,Vector3(0,-0.2,0),Vector3(50,0.4,50),Color(0.19,0.32,0.19))

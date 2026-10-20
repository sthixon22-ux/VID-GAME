class_name GearVisual
extends RefCounted
static func build(family: String, color_: Color) -> Node3D:
 var root=Node3D.new()
 var wood=Color("79543a")
 var metal=color_
 if family=="unarmed": return root
 if family=="bow":
  for side in [-1,1]:
   var limb=Art.box(root,Vector3(side*0.16,0,0),Vector3(0.08,0.9,0.09),wood)
   limb.rotation.z=side*0.25
  Art.box(root,Vector3(0,0,-0.07),Vector3(0.025,1,0.025),Color("ded0b2"))
 elif family in ["staff","wand","spear","scythe"]:
  var length_=2.2 if family=="staff" else (1.8 if family!="wand" else 0.7)
  var grip=-0.6 if family=="staff" else (-0.3 if family!="wand" else 0.0)
  Art.shape(root,Vector3(0,grip,0),Vector3(0.09,length_,0.09),wood,"cylinder")
  if family in ["staff","wand"]: Art.shape(root,Vector3(0,grip-length_/2-0.12,0),Vector3(0.25,0.4,0.25),Color("83c6d4"),"cone").rotation.z=PI
  elif family=="spear": Art.shape(root,Vector3(0,grip-length_/2-0.12,0),Vector3(0.22,0.5,0.12),metal,"cone").rotation.z=PI
  else: Art.box(root,Vector3(0.28,grip-length_/2,0),Vector3(0.7,0.13,0.09),metal).rotation.z=-0.25
 elif family=="claws":
  for x in [-0.1,0,0.1]: Art.box(root,Vector3(x,0.35,0),Vector3(0.05,0.6,0.06),metal)
 elif family in ["axe","hammer","mace"]:
  Art.shape(root,Vector3(0,0.3,0),Vector3(0.1,0.9,0.1),wood,"cylinder")
  if family=="axe": Art.box(root,Vector3(0.18,0.7,0),Vector3(0.6,0.4,0.1),metal)
  elif family=="hammer": Art.box(root,Vector3(0,0.7,0),Vector3(0.65,0.34,0.32),metal)
  else: Art.shape(root,Vector3(0,0.75,0),Vector3.ONE*0.4,metal)
 else:
  var length_=1.2 if family=="greatsword" else 0.5
  Art.box(root,Vector3(0,length_/2+0.15,0),Vector3(0.16,length_,0.07),metal)
  Art.box(root,Vector3(0,0.1,0),Vector3(0.35,0.06,0.1),Color("d0ae70"))
  Art.box(root,Vector3(0,-0.06,0),Vector3(0.1,0.3,0.1),wood)
 return root

static func item(item_name: String) -> Node3D:
 var entry: Dictionary=State.equipment_data[item_name]
 if entry.weapon_type!="sword": return build(entry.weapon_type,Color(entry.color))
 var source=load("res://assets/vendor/kaykit/Knight.glb").instantiate()
 var weapon: MeshInstance3D=source.find_child("1H_Sword",true,false).duplicate()
 source.free()
 if item_name!="Iron Sword":
  var material=StandardMaterial3D.new()
  material.albedo_color=Color(entry.color)
  material.metallic=0.4
  material.roughness=0.35
  weapon.material_override=material
 if item_name=="Moonleaf Saber": weapon.scale*=Vector3(0.75,1.08,0.75)
 weapon.show()
 return weapon

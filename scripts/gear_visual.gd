class_name GearVisual
extends RefCounted
static func item(item_name: String) -> Node3D:
 if InventoryBook.data.has(item_name): return supply(item_name)
 var entry:Dictionary=State.equipment_data[item_name]
 return load("res://assets/models/gear/%s.glb" % entry.get("visual_id",entry.id)).instantiate()
static func supply(id:String)->Node3D:
 var root=Node3D.new()
 var data:Dictionary=InventoryBook.data[id]
 if id=="treat":
  Art.shape(root,Vector3.ZERO,Vector3(0.4,0.15,0.3),Color(data.color))
  Art.shape(root,Vector3(0,0.1,0),Vector3(0.35,0.1,0.25),Color("75573c"))
 else:
  var glass=Art.shape(root,Vector3.ZERO,Vector3(0.35,0.4,0.35),Color(data.color))
  glass.material_override.metallic=0.3
  glass.material_override.roughness=0.18
  Art.shape(root,Vector3(0,0.25,0),Vector3(0.12,0.2,0.12),Color("b8c2b2"),"cylinder")
  Art.shape(root,Vector3(0,0.35,0),Vector3(0.14,0.08,0.14),Color("896a44"),"cylinder")
  Art.shape(root,Vector3(0,0.03,-0.17),Vector3(0.15,0.16,0.03),Color("e7dbc2"))
 return root

static func bounds(node:Node3D,transform_:Transform3D=Transform3D.IDENTITY)->AABB:
 var boxes:Array[AABB]=[]
 gather_bounds(node,transform_,boxes)
 if boxes.is_empty(): return AABB()
 var result=boxes[0]
 for box in boxes: result=result.merge(box)
 return result
static func gather_bounds(node:Node3D,transform_:Transform3D,boxes:Array[AABB]):
 var next=transform_*node.transform
 if node is MeshInstance3D and node.mesh: boxes.append(next*node.get_aabb())
 for child in node.get_children():
  if child is Node3D: gather_bounds(child,next,boxes)

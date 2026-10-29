class_name GearVisual
extends RefCounted
static func item(item_name: String) -> Node3D:
 if InventoryBook.data.has(item_name): return supply(item_name)
 var entry:Dictionary=State.equipment_data[item_name]
 var model=load("res://assets/models/gear/%s.glb" % entry.get("visual_id",entry.id)).instantiate()
 EquipmentStyle.decorate(model,entry)
 return model
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

static func arrow()->Node3D:
 var root=Node3D.new()
 var shaft=Art.shape(root,Vector3(.43,0,0),Vector3(.012,.86,.012),Color("b18a55"),"cylinder")
 shaft.rotation.z=-PI/2
 var head=Art.shape(root,Vector3(.9,0,0),Vector3(.055,.14,.055),Color("c0d3dc"),"cone")
 head.rotation.z=-PI/2
 for i in 3:
  var feather=Art.box(root,Vector3(.06,0,0),Vector3(.12,.055,.008),Color("e2ded0"))
  feather.rotation.x=i*TAU/3
 return root

static func quiver()->Node3D:
 var root=Node3D.new()
 var leather=Art.shape(root,Vector3(0,.1,0),Vector3(.18,.5,.18),Color("68472f"),"cylinder")
 leather.mesh.cap_top=false
 Art.shape(root,Vector3(0,.34,0),Vector3(.20,.04,.20),Color("b59859"),"cylinder")
 for i in 4:
  var arrow_=arrow()
  root.add_child(arrow_)
  arrow_.position=Vector3((i%2-.5)*.065,.50+(i%2)*.04,(i/2-.5)*.065)
  arrow_.rotation.z=-PI/2
  arrow_.scale=Vector3.ONE*.5
 return root

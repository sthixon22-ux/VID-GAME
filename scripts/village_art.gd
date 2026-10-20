class_name VillageArt
extends RefCounted
static func bounds(node: Node3D, parent: Transform3D=Transform3D.IDENTITY) -> AABB:
 var transform_=parent*node.transform
 var result=AABB()
 if node is MeshInstance3D: result=transform_*node.get_aabb()
 for child in node.get_children():
  if child is Node3D:
   var child_bounds=bounds(child,transform_)
   if child_bounds.size.length()>0:
    result=child_bounds if result.size.length()==0 else result.merge(child_bounds)
 return result
static func piece(root: Node3D, model: String, point: Vector3, dimensions: Vector3, yaw: float=0) -> Node3D:
 var holder=Node3D.new()
 root.add_child(holder)
 holder.position=point
 holder.rotation.y=yaw
 var asset=load("res://assets/vendor/quaternius_village/%s.gltf" % model).instantiate()
 var box=bounds(asset)
 var scale_=dimensions/Vector3(maxf(box.size.x,0.01),maxf(box.size.y,0.01),maxf(box.size.z,0.01))
 holder.add_child(asset)
 asset.scale=scale_
 asset.position=-Vector3(box.get_center().x,box.position.y,box.get_center().z)*scale_
 return holder
static func cottage(root: Node3D, point: Vector3):
 var house=Node3D.new()
 root.add_child(house)
 house.position=point
 Art.box(house,Vector3(0,1.2,0),Vector3(3.55,2.4,3.0),Color.WHITE).material_override=Art.surface(Color("f2ddbb"),"plaster",2)
 piece(house,"Wall_Plaster_WoodGrid",Vector3(0,0,1.6),Vector3(3.7,2.5,0.15))
 piece(house,"Wall_Plaster_WoodGrid",Vector3(-1.85,0,0),Vector3(3.2,2.5,0.15),PI/2)
 piece(house,"Wall_Plaster_WoodGrid",Vector3(1.85,0,0),Vector3(3.2,2.5,0.15),PI/2)
 piece(house,"Wall_Plaster_Door_Flat",Vector3(0,0,-1.6),Vector3(3.7,2.5,0.18),PI)
 piece(house,"Door_1_Flat",Vector3(0,0,-1.72),Vector3(0.95,1.85,0.08),PI)
 piece(house,"Roof_2x4_RoundTile",Vector3(0,2.5,0),Vector3(4.5,1.5,3.9))
 piece(house,"Prop_Chimney2",Vector3(1.1,3.05,0.5),Vector3(0.55,1.25,0.65))
 for x in [-1.16,1.16]:
  piece(house,"Window_Wide_Flat1",Vector3(x,0.9,-1.73),Vector3(0.65,0.8,0.1),PI)
  piece(house,"WindowShutters_Wide_Flat_Open",Vector3(x,0.87,-1.78),Vector3(1.0,0.85,0.12),PI)
 piece(house,"Prop_Vine1",Vector3(-1.72,0.15,-1.85),Vector3(0.5,1.5,0.1),PI)
 piece(house,"Prop_Crate",Vector3(2.4,0,0.5),Vector3(0.8,0.8,0.8))

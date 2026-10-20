class_name CameraObstacles
extends RefCounted
# Camera-only layer: these conservative art volumes do not change quest/movement geometry.
const LAYER=128
static func box(parent: Node3D, center: Vector3, size_: Vector3) -> StaticBody3D:
 var body=StaticBody3D.new()
 body.name="CameraBlocker"
 body.collision_layer=LAYER
 body.collision_mask=0
 body.position=center
 var collider=CollisionShape3D.new()
 var shape=BoxShape3D.new()
 shape.size=size_
 collider.shape=shape
 body.add_child(collider)
 parent.add_child(body)
 return body
static func sphere(parent: Node3D, center: Vector3, radius: float) -> StaticBody3D:
 var body=StaticBody3D.new()
 body.name="CanopyCameraBlocker"
 body.collision_layer=LAYER
 body.collision_mask=0
 body.position=center
 var collider=CollisionShape3D.new()
 var shape=SphereShape3D.new()
 shape.radius=radius
 collider.shape=shape
 body.add_child(collider)
 parent.add_child(body)
 return body

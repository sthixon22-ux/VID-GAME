class_name ExplorationCamera
extends Camera3D
const RADIUS=0.22
const PADDING=0.08
var distance=8.0
var initialized=false
var smooth_direction=Vector3.BACK
var last_safe_distance=8.0
func update_view(focus: Vector3, desired_offset: Vector3, delta: float):
 var desired_distance=desired_offset.length()
 if desired_distance<0.01: return
 var direction=desired_offset/desired_distance
 if not initialized:
  smooth_direction=direction
  distance=desired_distance
  initialized=true
 else: smooth_direction=smooth_direction.lerp(direction,1.0-exp(-12.0*delta)).normalized()
 var query=PhysicsShapeQueryParameters3D.new()
 var shape=SphereShape3D.new()
 shape.radius=RADIUS
 query.shape=shape
 query.transform=Transform3D(Basis.IDENTITY,focus)
 query.motion=smooth_direction*desired_distance
 query.collision_mask=CameraObstacles.LAYER
 query.margin=0.02
 var hit=get_world_3d().direct_space_state.cast_motion(query)
 var safe_distance=desired_distance
 if hit.size()>0 and hit[0]<1.0: safe_distance=maxf(0.05,desired_distance*hit[0]-PADDING)
 last_safe_distance=safe_distance
 # Pull in immediately; ease out only after an obstruction has cleared.
 distance=minf(safe_distance,lerpf(distance,safe_distance,1.0-exp(-5.0*delta))) if safe_distance>distance else safe_distance
 position=focus+smooth_direction*distance
 near=0.06
 look_at(focus)

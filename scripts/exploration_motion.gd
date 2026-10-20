class_name ExplorationMotion
extends RefCounted
const MAX_STEP=0.12
static func move(position_: Vector3, displacement: Vector3, can_walk: Callable) -> Vector3:
 # Small axis-separated steps preserve the existing slide behavior without
 # letting a single long frame jump across a river, wall or tree trunk.
 var horizontal=Vector3(displacement.x,0,displacement.z)
 var count=maxi(1,ceili(horizontal.length()/MAX_STEP))
 var step=horizontal/count
 var result=position_
 for i in range(count):
  if can_walk.call(Vector3(result.x+step.x,0,result.z)): result.x+=step.x
  if can_walk.call(Vector3(result.x,0,result.z+step.z)): result.z+=step.z
 return result

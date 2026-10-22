class_name WeaponPose
extends SkeletonModifier3D
# Presentation-only two-bone arm placement, evaluated after authored animation.
var hero:HeroVisual
var right_target:=Vector3.ZERO
var left_target:=Vector3.ZERO
var grip_error:=0.0
var left_error:=0.0
static func weapon_basis(up:Vector3)->Basis:
 var y=up.normalized()
 var x=y.cross(Vector3(0,0,1)).normalized()
 if x.length()<.1:x=Vector3.RIGHT
 return Basis(x,y,x.cross(y).normalized()).orthonormalized()
func _process_modification():
 if not is_instance_valid(hero) or hero.locked_pose:return
 var rig=get_skeleton()
 var family=hero.weapon_family
 if hero.action_remaining>0 and not hero.weapon_action:return
 if family not in ["unarmed","claws"]:
  curl_fingers(rig,"Right",family!="bow" or (hero.weapon_action and phase()<.63))
  if GameRules.TWO_HANDED.has(family) or hero.gear.get("Shield","None")!="None":curl_fingers(rig,"Left",true)
 if family=="bow":bow_pose(rig)
 elif family!="claws" and GameRules.TWO_HANDED.has(family):two_hand_pose(rig)
func arm(rig:Skeleton3D,side:String,target:Vector3,hand_basis:Basis):
 var a=rig.find_bone(side+"UpperArm")
 var b=rig.find_bone(side+"LowerArm")
 var c=rig.find_bone(side+"Hand")
 var root=rig.get_bone_global_pose(a).origin
 var elbow=rig.get_bone_global_pose(b).origin
 var hand=rig.get_bone_global_pose(c).origin
 var upper=root.distance_to(elbow)
 var lower=elbow.distance_to(hand)
 var delta=target-root
 var length=clampf(delta.length(),.04,upper+lower-.002)
 var direction=delta.normalized()
 var bend=Vector3(1 if side=="Left" else -1,-.4,-.3)
 bend=(bend-direction*bend.dot(direction)).normalized()
 var along=(upper*upper-lower*lower+length*length)/(2*length)
 var point=root+direction*along+bend*sqrt(maxf(0,upper*upper-along*along))
 rotate_bone(rig,a,elbow-root,point-root)
 elbow=rig.get_bone_global_pose(b).origin
 hand=rig.get_bone_global_pose(c).origin
 rotate_bone(rig,b,hand-elbow,target-elbow)
 var pose=rig.get_bone_global_pose(c)
 pose.basis=hand_basis
 rig.set_bone_global_pose(c,pose)
func rotate_bone(rig:Skeleton3D,index:int,from:Vector3,to:Vector3):
 if from.length()<.001 or to.length()<.001:return
 var pose=rig.get_bone_global_pose(index)
 pose.basis=Basis(Quaternion(from.normalized(),to.normalized()))*pose.basis
 rig.set_bone_global_pose(index,pose)
func phase()->float:
 if not hero.weapon_action:return 0
 return clampf(hero.action_elapsed/maxf(.01,hero.action_duration),0,1)
func two_hand_pose(rig:Skeleton3D):
 var family=hero.weapon_family
 var t=phase()
 var shoulders=(rig.get_bone_global_pose(rig.find_bone("RightUpperArm")).origin+rig.get_bone_global_pose(rig.find_bone("LeftUpperArm")).origin)*.5
 var long_shaft=family in ["spear","scythe","staff"]
 # Low diagonal guard: hilt by the right hip, blade/shaft across the body.
 var rest_orientation=weapon_basis(Vector3(.91,.37,.12))
 var rest_grip=shoulders+Vector3(-.16,-.24,.23)
 var rest_spacing=.62 if long_shaft else (.34 if family in ["axe","hammer"] else .28)
 var orientation=rest_orientation
 var grip=rest_grip
 var spacing=rest_spacing
 if hero.weapon_action:
  var stroke=smoothstep(.25,.65,t)
  var attack_orientation=Basis(Vector3.RIGHT,lerpf(-.9,1.1,stroke))
  var attack_grip=shoulders+Vector3(-.04,lerpf(.16,-.12,stroke),lerpf(.10,.23,stroke))
  var attack_spacing=.22
  if family in ["spear","scythe"]:
   attack_orientation=Basis(Vector3.RIGHT,PI/2)
   if family=="scythe":attack_orientation=Basis(Vector3.UP,lerpf(-.8,.8,stroke))*attack_orientation
   attack_grip=shoulders+Vector3(-.04,-.12,.06+.08*sin(stroke*PI))
   attack_spacing=.29
  var blend=smoothstep(0,.18,t)*(1-smoothstep(.78,1,t))
  orientation=Basis(rest_orientation.get_rotation_quaternion().slerp(attack_orientation.get_rotation_quaternion(),blend))
  grip=rest_grip.lerp(attack_grip,blend)
  spacing=lerpf(rest_spacing,attack_spacing,blend)
 var hand_rotation=orientation*hero.grip_basis.inverse()
 right_target=grip-hand_rotation*hero.palm_offset
 arm(rig,"Right",right_target,hand_rotation)
 var palm=grip+orientation*Vector3(0,spacing*hero.weapon_scale,0)
 var left_rotation=orientation*Basis(Vector3.UP,PI)*hero.grip_basis.inverse()
 left_target=palm-left_rotation*hero.palm_offset
 arm(rig,"Left",left_target,left_rotation)
 grip_error=rig.get_bone_global_pose(rig.find_bone("RightHand")).origin.distance_to(right_target)
 left_error=rig.get_bone_global_pose(rig.find_bone("LeftHand")).origin.distance_to(left_target)
func bow_carry(rig:Skeleton3D):
 # The free right arm retains its authored idle/walk/sprint motion.
 var shoulder=rig.get_bone_global_pose(rig.find_bone("LeftUpperArm")).origin
 var orientation=Basis(Vector3.UP,-PI/2)*Basis(Vector3.FORWARD,.12)
 var left_rotation=orientation*Basis(Vector3.UP,PI)*hero.grip_basis.inverse()
 var grip=shoulder+Vector3(.03,-.38,.04)
 left_target=grip-left_rotation*hero.palm_offset
 arm(rig,"Left",left_target,left_rotation)
 left_error=rig.get_bone_global_pose(rig.find_bone("LeftHand")).origin.distance_to(left_target)
 grip_error=0
 hero.update_bow(0,0)
func bow_pose(rig:Skeleton3D):
 if not hero.weapon_action:
  bow_carry(rig)
  return
 var t=phase()
 var draw=smoothstep(.05,.48,t) if hero.weapon_action else .12
 if t>.62:draw=lerpf(1,0,smoothstep(.62,.76,t))
 var chest=rig.find_bone("Chest")
 var torso=rig.get_bone_global_pose(chest)
 torso.basis=Basis(Vector3.UP,-PI*.40*draw)*torso.basis
 rig.set_bone_global_pose(chest,torso)
 var head=rig.find_bone("Head")
 var head_pose=rig.get_bone_global_pose(head)
 head_pose.basis=Basis.IDENTITY
 rig.set_bone_global_pose(head,head_pose)
 var orientation=Basis(Vector3.UP,-PI/2)
 var left_rotation=orientation*Basis(Vector3.UP,PI)*hero.grip_basis.inverse()
 var grip=Vector3(0,1.43,lerpf(.34,.44,draw))
 left_target=grip-left_rotation*hero.palm_offset
 arm(rig,"Left",left_target,left_rotation)
 var right_rotation=Basis(Vector3.UP,PI/2)*hero.grip_basis.inverse()
 var nock=grip+Vector3(0,0,-.08-draw*.23)
 right_target=nock-right_rotation*hero.palm_offset
 arm(rig,"Right",right_target,right_rotation)
 hero.update_bow(draw,t)
 left_error=rig.get_bone_global_pose(rig.find_bone("LeftHand")).origin.distance_to(left_target)
 grip_error=rig.get_bone_global_pose(rig.find_bone("RightHand")).origin.distance_to(right_target)

func curl_fingers(rig:Skeleton3D,side:String,closed:bool):
 for finger in ["Index","Middle","Ring","Little"]:
  for part in ["Proximal","Intermediate","Distal"]:
   var index=rig.find_bone(side+finger+part)
   if index>=0:rig.set_bone_pose_rotation(index,Quaternion(Vector3.RIGHT,.85 if closed else .08))

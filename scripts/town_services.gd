class_name TownServices
extends RefCounted
const DOORS={
 "forest":[[Vector3(-8,0,2),"weapons","Reed & Steel · Weapons"],[Vector3(7,0,2),"armor","The Stitch & Shield · Armor"],[Vector3(-9,0,-7),"items","Mira’s Supplies · Items"],[Vector3(8,0,-8),"inn","The Wayfarer · Inn"]],
 "mirefen":[[Vector3(-8,0,-8),"weapons","Tamsin’s Reed & Steel"],[Vector3(8,0,-8),"armor","Beren’s Dry Thread"],[Vector3(-8,0,-15),"items","Sella’s Supplies"],[Vector3(8,0,-15),"inn","The Lantern Rest · Inn"]]}
static func nearby(region:String,pos:Vector3)->Array:
 for door in DOORS.get(region,[]):
  if pos.distance_to(door[0])<1.85:return door
 return []
static func signs(root:Node3D,region:String):
 for door in DOORS.get(region,[]):
  var label=Art.sign_(root,door[0]+Vector3(0,2.2,0),door[2]+"\n[E] Enter")
  label.visibility_range_end=24
  label.pixel_size=.008
  var mat=Art.surface(Color("9b8054"),"wood",1)
  var step=Art.box(root,door[0]+Vector3(0,-.02,0),Vector3(1.7,.12,1.1),Color.WHITE)
  step.material_override=mat
static func shop(region:String,service:String)->String:
 var prefix="reedcross" if region=="mirefen" else "willowbrook"
 return prefix+"_"+service
static func enter(tree:SceneTree,region:String,door:Array):
 State.hero.town_visit={"region":region,"service":door[1],"name":door[2],"position":[door[0].x,0,door[0].z-1.1]}
 State.hero.journey.region="interior"
 State.remember_position(Vector3(0,0,3.5))
 State.shop_id=shop(region,door[1])
 State.save_game()
 tree.change_scene_to_file("res://scenes/town_interior.tscn")
static func inn_price(region:String)->int:return 24 if region=="mirefen" else 12
static func rest(region:String)->bool:
 var price=inn_price(region)
 if State.hero.gold<price:return false
 State.hero.gold-=price
 State.restore()
 State.save_game()
 return true

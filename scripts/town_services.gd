class_name TownServices
extends RefCounted
const DOORS={
 "sahir":[[Vector3(-8,0,8),"weapons","Caravan Blades"],[Vector3(8,0,8),"armor","Sunveil Tailor"],[Vector3(-8,0,0),"items","Oasis Supplies"],[Vector3(8,0,0),"inn","The Copper Moon"]],
 "kharholt":[[Vector3(-8,0,8),"weapons","Brann’s Anvil"],[Vector3(8,0,8),"armor","Forgeguard Armory"],[Vector3(-8,0,0),"items","Mountain Provisions"],[Vector3(8,0,0),"inn","The Hearthstone"]],
 "forest":[[Vector3(-8,0,8),"weapons","Reed & Steel · Weapons"],[Vector3(7,0,8),"armor","The Stitch & Shield · Armor"],[Vector3(-9,0,-1),"items","Mira’s Supplies · Items"],[Vector3(8,0,-2),"inn","The Wayfarer · Inn"]],
 "mirefen":[[Vector3(-8,0,-2),"weapons","Tamsin’s Reed & Steel"],[Vector3(8,0,-2),"armor","Beren’s Dry Thread"],[Vector3(-8,0,-9),"items","Sella’s Supplies"],[Vector3(8,0,-9),"inn","The Lantern Rest · Inn"]]}
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
 if region in ["sahir","kharholt"]:return region+"_"+service
 var prefix="reedcross" if region=="mirefen" else "willowbrook"
 return prefix+"_"+service
static func enter(tree:SceneTree,region:String,door:Array):
 State.hero.town_visit={"region":region,"service":door[1],"name":door[2],"position":[door[0].x,0,door[0].z+1.1]}
 State.hero.journey.region="interior"
 State.remember_position(Vector3(0,0,3.5))
 State.shop_id=shop(region,door[1])
 State.save_game()
 tree.change_scene_to_file("res://scenes/town_interior.tscn")
static func inn_price(region:String)->int:return {"forest":12,"mirefen":24,"sahir":32,"kharholt":45}.get(region,12)
static func rest(region:String)->bool:
 var price=inn_price(region)
 if State.hero.gold<price:return false
 State.hero.gold-=price
 State.restore()
 if State.hero.companion.active and not State.companion_record().is_empty():State.companion_record().field_used=false
 State.save_game()
 return true

static func exit_position(visit:Dictionary)->Vector3:
 # Resolve old indoor saves against today's front door instead of yesterday's rear exit.
 for door in DOORS.get(visit.get("region","forest"),[]):
  if door[1]==visit.get("service",""):return door[0]+Vector3(0,0,1.1)
 return Vector3.ZERO

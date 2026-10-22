extends Node
var checks:=0
var failures:=0
func check(value:bool,label:String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func settle():
 for i in 5:await get_tree().process_frame
func change(path:String):
 get_tree().change_scene_to_file(path)
 await settle()
 return get_tree().current_scene
func run():
 State.reset()
 var before=JSON.stringify(State.hero)
 for sex in ["Male","Female"]:
  for chest in WardrobeVisual.CHESTS:
   var hero=HeroVisual.new({"Weapon":"None","Chest":chest,"Shield":"None"},{"class":"Paladin","sex":sex})
   add_child(hero);await settle()
   check(hero.get_meta("wardrobe_style")==WardrobeVisual.profile(chest).style,"Chest selects actual visual profile: "+sex+" "+chest)
   if chest=="Steel Cuirass":check(hero.find_child("EquippedChestSkinnedPlate",true,false)!=null,"Steel armor adds a deforming plate surface: "+sex)
   if chest in ["Verdant Robe","Sluicekeeper Robe"]:check(hero.find_child("EquippedChestRobeSkirt",true,false)!=null,"Robes change silhouette: "+sex+" "+chest)
   if chest=="Reedcoat":check(hero.find_child("EquippedChestCoatTails",true,false)!=null,"Reedcoat adds visible coat tails: "+sex)
   hero.queue_free();await settle()
 for sex in ["Male","Female"]:
  for family in ["sword","dagger","greatsword","axe","hammer","staff","spear","scythe","bow","wand","mace","claws"]:
   var item=""
   for name_ in State.equipment_data:
    if State.equipment_data[name_].get("weapon_type")==family:item=name_;break
   if item.is_empty():continue
   var hero=HeroVisual.new({"Weapon":item,"Chest":"Leather Vest","Shield":"Oak Shield"},{"class":"Warrior","sex":sex})
   add_child(hero);hero.battle=true;await settle()
   var prop=hero.find_child("EquippedWeapon",true,false)
   check(prop.get_parent().bone_name==("LeftHand" if family=="bow" else "RightHand"),"Weapon uses correct hand: "+sex+" "+family)
   check((hero.find_child("EquippedShield",true,false)==null)==GameRules.TWO_HANDED.has(family),"Two-handed shield exclusion stays correct: "+family)
   if family=="bow":
    check(not hero.bow_arrow.visible and not hero.weapon_action,"Idle bow has no nocked arrow: "+sex)
    check(hero.pose_modifier.left_target.y<1.15,"Idle bow rests one-handed beside the hip: "+sex)
   elif family in ["greatsword","axe","hammer","staff","spear","scythe"]:
    var axis=hero.skeleton.global_basis.inverse()*prop.global_basis.y.normalized()
    check(absf(axis.x)>.7 and absf(axis.y)<.65,"Two-handed shaft lies diagonally across the body: "+sex+" "+family)
    check(hero.pose_modifier.right_target.distance_to(hero.pose_modifier.left_target)>.15,"Two-hand guard has separated hands: "+sex+" "+family)
   elif family=="sword":
    check(prop.basis.is_equal_approx(Basis(Vector3.BACK,-PI/2).scaled(Vector3.ONE*.65)) and prop.position.is_equal_approx(Vector3(.052,.075,0)),"Approved regular sword grip stays unchanged: "+sex)
   hero.play_action("Attack")
   hero.set_process(false)
   var clip=hero.player.current_animation
   check(clip!="OverhandThrow","Weapon action avoids throwing fallback: "+family)
   for fraction in [.1,.4,.6,.8]:
    hero.player.seek(hero.player.get_animation(clip).length*fraction,true)
    hero.player.pause()
    hero.action_elapsed=hero.action_duration*fraction
    await settle()
    if family in ["greatsword","axe","hammer","staff","spear","scythe","bow"]:
     check(hero.pose_modifier.grip_error<.025 and hero.pose_modifier.left_error<.025,"Both hand grips stay within 2.5 cm at phase %.1f: %s %s (%.3f/%.3f)" % [fraction,sex,family,hero.pose_modifier.grip_error,hero.pose_modifier.left_error])
   if family=="bow":
    check(hero.bow_arrow!=null and hero.bow_string.mesh!=null and hero.find_child("EquippedQuiver",true,false)!=null,"Bow has real arrow and changing string")
    check(hero.arrow_released and not hero.bow_arrow.visible,"Bow releases the arrow after drawing")
    hero.weapon_action=false;hero.action_remaining=0
    hero.motion(false)
    await settle()
    check(not hero.bow_arrow.visible and hero.pose_modifier.left_target.y<1.15,"Bow returns to relaxed carry after attack: "+sex)
   hero.queue_free();await settle()
 var host=Node3D.new();add_child(host)
 var archer=HeroVisual.new({"Weapon":"Woodland Bow","Chest":"Leather Vest","Shield":"None"},{"class":"Ranger","sex":"Male"})
 host.add_child(archer);archer.battle=true
 var target=Art.actor("Goblin");host.add_child(target)
 target.position=Vector3(0,0,-4)
 await BattleMotion.present(host,archer,target,"Aimed Shot")
 check(archer.arrow_released,"Actual battle presentation releases bow projectile before impact")
 check(archer.get_meta("shot_target_world")==target.global_position+Vector3.UP*1.2,"Bow projectile aims at actual battle target")
 check(archer.action_elapsed>=archer.action_duration*.8,"Bow impact waits for draw, release and flight")
 archer.play_action("Quickshot")
 check(archer.weapon_action and archer.player.current_animation=="Idle","Learned class bow techniques also use draw/release instead of sword fallback")
 host.queue_free();await settle()
 check(JSON.stringify(State.hero)==before,"Equipment art and animation do not mutate gameplay data")
 var building_root=Node3D.new();add_child(building_root)
 var house=VillageArt.cottage(building_root,Vector3.ZERO)
 var door_mesh=house.find_child("Door_1_Flat",true,false) as Node3D
 check(door_mesh!=null and door_mesh.position.z>1.6 and absf(door_mesh.rotation.y)<.01,"Visible door geometry faces the default camera")
 building_root.queue_free();await settle()
 var old_visit={"region":"forest","service":"weapons","position":[-8,0,0]}
 check(TownServices.exit_position(old_visit).is_equal_approx(Vector3(-8,0,9.1)),"Older interior saves exit at the new front door")
 check(Art.surface(Color.WHITE,"wood",1) is ShaderMaterial,"Wood uses world-scale atlas sampling")
 check(Art.surface(Color.WHITE,"grass",1) is ShaderMaterial,"Terrain uses continuous world-scale detail")
 State.new_adventure();State.create_hero("Town Tester","Wizard",0,0,0,["Monk","Assassin"],"Male")
 State.hero.journey.finished=true
 State.choose_companion("spirit_fox")
 State.hero.gold=1000
 for region in TownServices.DOORS:
  for door in TownServices.DOORS[region]:
   State.hero.journey.region=region
   State.remember_position(door[0])
   var area=await change(State.travel_scene())
   if "grace" in area:area.grace=999
   if "contact_grace" in area:area.contact_grace=999
   area.hero.position=door[0];area.interact()
   await settle()
   var interior=get_tree().current_scene
   check(interior.scene_file_path=="res://scenes/town_interior.tscn","Door enters building: "+region+" "+door[1])
   check(State.shop_id==TownServices.shop(region,door[1]),"Building selects correct regional service")
   State.save_game();State.reset();State.load_game()
   check(State.travel_scene()=="res://scenes/town_interior.tscn" and State.hero.town_visit.service==door[1],"Save/load resumes inside correct building")
   interior=await change(State.travel_scene())
   if door[1]=="inn":
    State.hero.hp=1;State.hero.mp=0;State.hero.gold=100
    var gold=int(State.hero.gold)
    interior.rest()
    check(State.hero.gold==gold-TownServices.inn_price(region) and State.hero.hp==State.stats().max_hp and State.hero.mp==State.stats().max_mp,"Inn charges exact price and restores party: "+region)
    State.hero.gold=0;State.hero.hp=1
    check(not TownServices.rest(region) and State.hero.hp==1 and State.hero.gold==0,"Unaffordable rest spends and restores nothing")
   else:
    interior.hero.position=Vector3(0,0,-1);interior.interact()
    await settle()
    var merchant=get_tree().current_scene
    check(merchant.scene_file_path=="res://scenes/character.tscn" and merchant.page=="shop","Indoor counter opens existing shop system")
    if door[1]=="items":
     State.hero.gold=100
     var potions=int(State.hero.potions)
     check(State.buy_supply("potion") and State.hero.potions==potions+1,"Item shop supplies use existing inventory")
    merchant.leave();await settle()
    interior=get_tree().current_scene
   interior.leave();await settle()
   var outside=get_tree().current_scene
   check(State.hero.journey.region==region and outside.scene_file_path==State.travel_scene(),"Exit returns to original town: "+region)
   var walk=outside.forest.can_walk(State.return_position) if region=="forest" else outside.walkable(State.return_position)
   check(walk,"Door exit position is outside building collision")
 var area=get_tree().current_scene
 var yaw_before=area.yaw
 var position_before=area.hero.position
 var key=InputEventKey.new();key.physical_keycode=KEY_RIGHT;key.keycode=KEY_RIGHT;key.pressed=true
 Input.parse_input_event(key);Input.flush_buffered_events()
 area._process(.25)
 check(area.yaw>yaw_before+.1 and area.hero.position.is_equal_approx(position_before),"Arrow key rotates exploration camera without moving the hero")
 var released=key.duplicate();released.pressed=false
 Input.parse_input_event(released);Input.flush_buffered_events()
 print("Equipment/town checks: %s Failures: %s" % [checks,failures])
 get_tree().quit(1 if failures else 0)

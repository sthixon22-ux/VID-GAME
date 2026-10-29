extends Node
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if ok:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func settle():
 for i in 8:await get_tree().process_frame
func run():
 UserSettings.set_option("muted",true);UserSettings.set_option("minimal_animations",true)
 State.new_adventure();State.create_hero("Ash","Barbarian",0,0,0,["Wizard","Healer"],"Male")
 State.hero.skills.Barbarian.append("adept")
 # The real grant node can change its internal ID; derive it from the catalog.
 for node in State.classes.Barbarian.nodes:
  if node.get("grants",[]).has("barbarian_adept"):State.hero.skills.Barbarian.append(node.id)
 State.hero.mp=100
 for weapon in ["Iron Sword","Oak Staff","None","Iron Axe"]:
  State.hero.equipment.Weapon=weapon
  var sim=Combat.new(State.hero,State.stats(),"goblin")
  check(sim.legal("Sundering Roar"),"Roar independent of weapon: "+weapon)
  sim.round_("Sundering Roar");check(sim.sunder>0 and sim.h.mp==91,"Roar pays MP and applies armor break: "+weapon)
 check(not SkillEffects.tooltip("Sundering Roar").contains("Requires axe"),"Roar tooltip no longer claims axe requirement")
 check(SkillEffects.tooltip("Dragon Slash").contains("Required weapons: sword"),"Physical techniques explain weapon requirements")
 # Stock covers every class's weapon families from the second area onward.
 for town in ["reedcross","sahir","kharholt"]:
  var stock=ShopBook.stock(town+"_weapons")
  for family in ["sword","greatsword","axe","hammer","spear","bow","dagger","mace","staff","wand","claws","scythe"]:
   check(stock.any(func(name_):return State.equipment_data[name_].weapon_type==family),"Weapon family stocked: "+town+" "+family)
  for kind in ["plate","robe","leather","coat"]:check(ShopBook.stock(town+"_armor").any(func(n):return WardrobeVisual.profile(n).style==kind),"Armor silhouette stocked: "+town+" "+kind)
 for item in ["Flamebrand","Dragonbone Greatsword","Stormcaller Spear","Moonstring Bow","Nightfang Daggers"]:
  var prop=GearVisual.item(item);add_child(prop)
  check(prop.has_meta("equipment_theme") and prop.find_child("Theme_*",true,false)!=null,"Named weapon has motif: "+item)
  prop.queue_free()
 for sex in ["Male","Female"]:
  for armor in ["Knight’s Harness","Runewoven Robe","Shadowstalker Leathers","Wildheart Mantle","Sunpriest Vestments","Wayfarer’s Wraps"]:
   var model=HeroVisual.new({"Chest":armor,"Weapon":"None","Shield":"None"},{"sex":sex,"class":"Barbarian"});add_child(model)
   check(model.has_meta("armor_theme"),"Visible themed outfit: "+armor+sex)
   model.queue_free()
 # True dragons have exactly two hind legs plus two wing-arm chains; drakes retain their source anatomy.
 var dragon=CompanionVisual.build("dragon");add_child(dragon);await settle()
 for bone in ["UpperWingArm.L","UpperWingArm.R","HindThigh.L","HindThigh.R"]:check(dragon.skeleton.find_bone(bone)>=0,"Four-limb dragon bone: "+bone)
 check(dragon.skeleton.find_bone("Wing1.L")==-1 and dragon.skeleton.find_bone("UpperArm.L")==-1,"No independent back wings or extra forearms on true dragons")
 for clip in ["Idle","Walk","Run","Attack","Guard","Hit","Death","Flight"]:check(dragon.player.has_animation(dragon.resolve_clip(clip)),"New dragon animation imports: "+clip)
 dragon.queue_free()
 var drake=FrontierCreature.new("SandDrake");add_child(drake);await settle()
 check(drake.native.companion_id=="drake","Sandglass drakes retain separate anatomy")
 drake.queue_free()
 var boss=FrontierCreature.new("GlassSovereign");add_child(boss);await settle()
 check(boss.native.companion_id=="dragon" and boss.native.skeleton.find_bone("HindThigh.L")>=0,"Namarra uses the four-limbed dragon derivative")
 boss.queue_free()
 # Item destination validation and no spend on cancel/invalid travel.
 State.hero.items.waystone=2;State.hero.items.escape_rope=2
 check(not State.use_item("waystone","kharholt") and State.item_count("waystone")==2,"Undiscovered town cannot spend a waystone")
 State.hero.journey.finished=true;State.hero.campaign.reported=true;ExpeditionRules.progress(State.hero).cleared.append("sahir")
 check(State.use_item("waystone","kharholt") and State.hero.journey.region=="kharholt" and State.item_count("waystone")==1,"Waystone travels to discovered town and spends one")
 for area in ["dungeon","reliquary","emberglass","ironroot"]:
  State.hero.journey.region=area;State.hero.items.escape_rope=1
  check(State.use_item("escape_rope") and State.hero.journey.region==TravelRules.ENTRANCES[area][0],"Return Thread exits correct dungeon: "+area)
 State.hero.journey.region="forest";State.hero.items.escape_rope=1
 check(not State.use_item("escape_rope") and State.item_count("escape_rope")==1,"Return Thread cannot be wasted outside a dungeon")
 State.hero.items.ether=1;State.hero.items.elixir=1;State.hero.items.treat=1
 State.hero.mp=0
 var supply_sim=Combat.new(State.hero,State.stats(),"goblin")
 supply_sim.hero_turn("Moon Ether")
 check(supply_sim.h.mp==20 and supply_sim.h.items.ether==0,"Battle ether restores MP and consumes inventory")
 check(not supply_sim.legal("Moon Ether"),"Battle ether cannot be used without stock")
 # All capstones are distinct, limited and persisted independently.
 for id in State.companions:
  State.hero.companion.owned=[];State.hero.companion.records={};State.choose_companion(id)
  var record=State.companion_record();record.skills=["capstone"];record.field_used=false
  State.hero.hp=1;State.hero.mp=0
  if id=="spirit_fox":record.hp=0
  State.hero.journey.region="ironroot" if id=="dragon" else "forest"
  var success=CompanionRules.field(State.hero,"0" if id=="griffin" else "mirefen" if id=="warhorse" else "")
  check(success and record.field_used,"Companion field capstone activates: "+id)
  check(not CompanionRules.field(State.hero,"forest"),"Companion field cannot spam: "+id)
  State.restore();check(record.field_used,"Camp healing does not recharge field power: "+id)
  State.hero.gold=1000;check(TownServices.rest("forest") and not record.field_used,"Paid active-companion inn rest recharges: "+id)
  var total=0
  for node in State.companions[id].nodes:total+=int(node.cost)
  check(total==80,"Long companion tree costs 80 bond points: "+id)
 check(CompanionRules.threshold(20)>2000,"Companion XP progression grows slowly")
 var sim=Combat.new(State.hero,State.stats())
 check(sim.damage(40,100)>1,"High defense cannot trivially reduce all hits to one")
 # Portrait identity is actual model/appearance rather than a default SVG woman.
 var box=Dialogue.new();add_child(box);await settle()
 for who in ["Hero","King Aldren","Archivist Safiya","Vorr"]:
  box.database.test=[[who,"Portrait test"]];box.show_id("test");await settle()
  check(box.face_view.identity==who and box.face_view.model!=null,"Portrait renders speaker: "+who)
  box.advance()
 box.queue_free();await settle()
 # Repeat dungeon-four actual valve UI, deferred travel and model action paths.
 State.hero.journey.region="ironroot";State.remember_position(Vector3(0,0,3))
 get_tree().change_scene_to_file("res://scenes/ironroot.tscn");await settle()
 var area=get_tree().current_scene;area.grace=999
 var p=ExpeditionRules.progress(State.hero);p.rooms=["4100","4101"]
 for pass_ in 3:
  for i in 3:area.mechanism(i);area.puzzle.get_parent().get_parent().hide()
 check(area.get_tree()!=null,"Dungeon-four mechanisms tolerate repeated open/close")
 for mob in area.mobs:
  if mob.model.has_method("play_action"):mob.model.play_action("Attack");mob.model.play_action("Defeat")
 area.boss.play_action("Mountainfall");await settle()
 check(area.boss.native.player!=null,"Dungeon-four boss animation remains valid")
 State.hero.companion.records[State.hero.companion.current].field_used=true
 check(State.save_game(),"Field power state saves")
 State.reset();State.load_game();check(State.companion_record().field_used,"Used field power persists after reload")
 print("Theme update checks: %s Failures: %s" % [checks,failures])
 await Sound.stop_all();get_tree().quit(1 if failures else 0)

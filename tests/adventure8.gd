extends Node
var checks=0
var failures=0
func check(value:bool,label:String):
 checks+=1
 if value: print("PASS: ",label)
 else:
  failures+=1
  push_error(label)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func settle():
 for i in range(6): await get_tree().process_frame
func scene(path:String):
 get_tree().change_scene_to_file(path)
 await settle()
 var result=get_tree().current_scene
 if result.scene_file_path=="res://scenes/world.tscn": result.contact_grace=999
 if result.scene_file_path=="res://scenes/dungeon.tscn": result.contact_grace=999
 return result
func prepare():
 State.new_adventure()
 State.create_hero("Traveler","Paladin",0,0,0,["Ranger","Druid"])
func dismiss(box:Dialogue):
 while box.active:box.advance()
func find_button(root:Node,prefix:String)->Button:
 for button in root.find_children("*","Button",true,false):
  if button.text.begins_with(prefix): return button
 return null
func total_xp()->int:
 return 35*int(State.hero.level)*(int(State.hero.level)-1)+int(State.hero.xp)
func run():
 UserSettings.set_option("minimal_animations",true)
 prepare()
 for key in GameRules.STAT_KEYS:
  var expected=roundi(.6*State.classes.Paladin.base_stats[key]+.2*State.classes.Ranger.base_stats[key]+.2*State.classes.Druid.base_stats[key])
  check(State.stats()[key]==expected,"All three classes contribute to "+key)
 var locked=State.hero.duplicate(true)
 for slot in ["primary","secondary_1","secondary_2"]:
  check(not State.set_class_slot(slot,"Wizard") and State.hero==locked,"Roles locked outside creation: "+slot)
 State.new_adventure()
 var creator=await scene("res://scenes/create.tscn")
 var before=creator.details.text
 creator.secondary2.select(creator.secondary2.item_count-1)
 creator.secondary2.item_selected.emit(creator.secondary2.selected)
 check(creator.details.text!=before and creator.details.text.contains("60%"),"Second secondary picker refreshes blended stats live")
 creator.select_class("Wizard")
 check(creator.details.text.contains("Wizard /") and creator.details.text.contains("Level 10"),"Creation previews baseline and future growth for the selected combo")
 prepare()
 State.buy("Iron Sword")
 State.equip("Weapon","Iron Sword")
 State.hero.hp=10
 check(State.use_item("potion") and State.hero.hp==55 and State.item_count("potion")==2,"Inventory potion consumes one and restores 45 HP")
 State.hero.mp=0
 check(State.use_item("ether") and State.hero.mp==20 and State.item_count("ether")==0,"Ether restores MP outside combat")
 State.hero.companion.intro_hp=5
 check(State.use_item("treat") and State.hero.companion.intro_hp==40,"Rations heal the companion outside combat")
 State.restore()
 State.hero.items.ether=2
 var count=State.hero.potions
 check(not State.use_item("potion") and State.hero.potions==count,"Full HP does not waste a potion")
 check(not State.use_item("ether") and State.hero.items.ether==2,"Full MP does not waste ether")
 State.save_game()
 State.reset()
 State.load_game()
 check(State.hero.items.ether==2 and State.hero.hp==State.stats().max_hp,"Consumables and recovery persist after reloading")
 for family in ["greatsword","axe","spear","bow","staff","claws"]:
  State.new_adventure()
  State.create_hero("Hands","Monk",0,0,0,["Paladin","Ranger"])
  if family in ["greatsword","axe","spear"]: State.hero.secondary=["Paladin","Warrior"]
  for item in ["Iron Sword","Oak Shield"]: State.grant_item(item)
  State.equip("Weapon","Iron Sword")
  State.equip("Shield","Oak Shield")
  var weapon=""
  for item in State.equipment_data:
   if State.equipment_data[item].slot=="Weapon" and State.equipment_data[item].get("weapon_type")==family:weapon=item;break
  State.grant_item(weapon)
  check(State.equip("Weapon",weapon) and State.hero.equipment.Shield=="None" and State.owns("Oak Shield"),family+" stows the shield while retaining ownership")
  check(not State.equip("Shield","Oak Shield"),family+" cannot equip a shield")
  check(not Combat.new(State.hero,State.stats()).legal("Shield Bash"),family+" disables shield abilities")
  var naked_def=int(State.stats().defense)
  State.hero.equipment.Shield="Oak Shield"
  check(State.stats().defense==naked_def and Combat.new(State.hero,State.stats()).h.equipment.Shield=="None","Invalid saved pair grants no shield stats: "+family)
  State.equip("Weapon","Iron Sword")
  check(State.equip("Shield","Oak Shield"),"One-handed sword restores shield eligibility after "+family)
 prepare()
 State.buy("Iron Sword")
 State.equip("Weapon","Iron Sword")
 State.menu_page="inventory"
 var menu=await scene("res://scenes/character.tscn")
 check(find_button(menu.body,"Use Healing Potion")!=null,"Dedicated inventory has a healing action")
 menu.show_page("shop")
 var snapshot=State.hero.duplicate(true)
 for item in State.equipment_data:
  if State.equipment_data[item].slot=="Any":continue
  menu.preview_shop_weapon(item)
  check(GearVisual.bounds(menu.shop_preview.pivot).size.length()>.1,"Model preview has geometry: "+item)
 for id in InventoryBook.data:
  menu.preview_supply(id)
  check(menu.shop_preview.item_name==id,"Supply has a preview: "+id)
 check(State.hero==snapshot,"Previewing all equipment and supplies never alters saved state")
 var world=await scene("res://scenes/world.tscn")
 check(world.hud_layer.map!=null and world.hud_layer.status.position.y>600,"Exploration HUD sits at the bottom with a corner map")
 world.hero.position=world.goblins[0].position
 world.contact_grace=0
 world._process(.01)
 await settle()
 check(get_tree().current_scene.scene_file_path=="res://scenes/battle.tscn","Touching an enemy starts battle without pressing E")
 get_tree().current_scene.return_to_adventure()
 await settle()
 world=get_tree().current_scene
 check(world.contact_grace>0,"Returning from battle has a contact grace period")
 State.hero.mastery=10
 world.hero.position=world.goblins[0].position
 world.contact_grace=0
 var resources=[State.hero.hp,State.hero.mp,State.hero.potions,State.hero.gold,State.hero.seed]
 world._process(.01)
 check(world.auto_panel.active and get_tree().current_scene==world,"Mastered contact opens a choice before loading the battle scene")
 check(find_button(world.auto_panel.content,"Fight normally")!=null and find_button(world.auto_panel.content,"Auto-Battle")!=null,"Mastery choice offers both battle modes")
 check(resources==[State.hero.hp,State.hero.mp,State.hero.potions,State.hero.gold,State.hero.seed],"Risk forecast does not spend resources or change the seed")
 world.auto_panel.resolve()
 check(State.cleared_until.has(0),"Auto-Battle resolves and clears the contacted encounter in exploration")
 world.auto_panel.close()
 check(world.contact_grace>=2.9,"Closing the encounter choice lets the player move away safely")
 State.restore()
 world.hero.position=world.goblins[1].position
 world.contact_grace=0
 world._process(.01)
 find_button(world.auto_panel.content,"Fight normally").pressed.emit()
 await settle()
 check(get_tree().current_scene.scene_file_path=="res://scenes/battle.tscn","Fight normally launches a mastered encounter")
 get_tree().current_scene.return_to_adventure()
 await settle()
 world=get_tree().current_scene
 world.hero.position=world.goblins[3].position
 world.contact_grace=0
 world._process(.01)
 await settle()
 check(get_tree().current_scene.scene_file_path=="res://scenes/battle.tscn" and get_tree().current_scene.sim.species=="bristleback","Goblin mastery does not unlock the plains species")
 get_tree().current_scene.return_to_adventure()
 await settle()
 world=get_tree().current_scene
 State.hero.hp=1
 State.hero.mp=0
 State.hero.potions=0
 State.hero.companion.active=false
 for seed_ in range(1,100):
  State.hero.seed=seed_
  if Combat.new(State.hero,State.stats()).auto_resolve()=="Defeat":break
 State.cleared_until.erase(0) # Respawn the already defeated fixture for the defeat scenario.
 world.hero.position=world.goblins[0].position
 world.contact_grace=0
 world._process(.01)
 check(world.auto_panel.active,"Weak mastered contact opens a real risk prompt before the defeat check")
 world.auto_panel.resolve()
 check(State.hero.hp==0 and State.return_position==Vector3.ZERO,"Auto defeat consumes health and records a retreat to camp")
 world.auto_panel.close()
 check(world.hero.position==Vector3.ZERO,"Auto defeat returns the outdoor hero to camp without a battle scene")
 var rest=InputEventKey.new()
 rest.pressed=true
 rest.keycode=KEY_R
 world._unhandled_input(rest)
 check(State.hero.hp==State.stats().max_hp and State.hero.mp==State.stats().max_mp,"Camp rest recovers from Auto-Battle defeat")
 prepare()
 State.buy("Iron Sword")
 State.equip("Weapon","Iron Sword")
 world=await scene("res://scenes/world.tscn")
 for id in QuestBook.data:
  var index=QuestBook.data.keys().find(id)
  world.hero.position=Forest.QUEST_NPCS[index]
  world.interact()
  dismiss(world.dialogue)
  check(State.hero.side_quests.started.has(id),"Town NPC starts quest: "+id)
 for i in range(3):
  world.hero.position=Forest.CRYSTALS[i]
  world.interact()
 check(State.hero.side_quests.crystals.size()==3,"Three distinct plains clusters can be collected")
 var gold=int(State.hero.gold)
 var xp=total_xp()
 world.hero.position=Forest.QUEST_NPCS[1]
 world.interact()
 dismiss(world.dialogue)
 check(State.last_reward.base==60 and State.hero.gold>=gold+60 and total_xp()==xp+70,"Gathering quest awards gold and XP through its NPC")
 gold=int(State.hero.gold)
 world.interact()
 dismiss(world.dialogue)
 check(State.hero.gold==gold,"Town quest reward cannot be claimed twice")
 for i in range(4):State.reward(false,"goblin")
 check(QuestBook.complete(State.hero,"roadwatch") and State.hero.mastery==0,"Slaying quest counts victories without granting normal mastery for auto wins")
 check(State.claim_side_quest("roadwatch") and State.last_reward.base==55,"Slaying quest awards its authored reward")
 State.hero.journey.region="dungeon"
 State.hero.journey.entered=true
 State.hero.journey.guards=[0,1]
 State.remember_position(Vector3(0,0,-10))
 var dungeon=await scene("res://scenes/dungeon.tscn")
 check(not dungeon.can_walk(Vector3(0,0,-25)),"Sealed dungeon gate blocks the boss corridor")
 dungeon.hero.position=dungeon.seals[0].position
 dungeon.interact()
 check(dungeon.puzzle_panel.get_parent().get_parent().visible and State.hero.journey.seals.is_empty(),"Defeating a guardian does not bypass its puzzle")
 for index in range(3):
  for turn in [1,3,2][index]:
   find_button(dungeon.puzzle_panel,"Dial %s:" % (index+1)).pressed.emit()
 check(State.hero.puzzles.solved.has("dials"),"Correct symbol alignment solves the dial puzzle through the UI")
 dungeon.puzzle_panel.get_parent().get_parent().hide()
 dungeon.interact()
 dismiss(dungeon.dialogue)
 check(State.hero.journey.seals==[0] and not dungeon.can_walk(Vector3(0,0,-25)),"One solved seal is insufficient for the boss gate")
 dungeon.hero.position=dungeon.seals[1].position
 dungeon.interact()
 find_button(dungeon.puzzle_panel,"Dawn bell").pressed.emit()
 check(State.hero.puzzles.sequence.is_empty(),"Wrong first bell clears the sequence")
 find_button(dungeon.puzzle_panel,"Water bell").pressed.emit()
 State.save_game()
 State.reset()
 State.load_game()
 check(State.hero.puzzles.sequence==[2] and State.hero.puzzles.solved.has("dials"),"Partial puzzle progress and solved puzzle survive saving")
 dungeon.open_puzzle(1)
 find_button(dungeon.puzzle_panel,"Dawn bell").pressed.emit()
 find_button(dungeon.puzzle_panel,"Leaf bell").pressed.emit()
 check(State.hero.puzzles.solved.has("song"),"Water, dawn, leaf solves the second puzzle")
 dungeon.puzzle_panel.get_parent().get_parent().hide()
 dungeon.interact()
 dismiss(dungeon.dialogue)
 check(State.hero.journey.seals.size()==2 and dungeon.can_walk(Vector3(0,0,-25)),"Both solved seals open the boss route")
 for id in State.companions:
  var model=CompanionVisual.build(id)
  var bounds=GearVisual.bounds(model)
  check(bounds.size.x>.5 and bounds.size.y>1 and model.has_node("Body"),"New companion has a complete authored model: "+id)
  model.free()
 var bad=State.hero.duplicate(true)
 bad.puzzles.dials=[99,0,0]
 check(not SaveStore.valid_nested(bad),"Malformed puzzle values are rejected by save validation")
 var old=State.hero.duplicate(true)
 old.save_schema_version=3
 old.world_version=7
 old.journey.region="forest"
 old.journey.position=[24.0,0.0,-12.0]
 old.erase("items")
 old.erase("puzzles")
 old.erase("side_quests")
 var roles=[old.primary]+old.secondary
 var points=int(old.points)
 var file=FileAccess.open(State.SAVE,FileAccess.WRITE)
 file.store_string(JSON.stringify(old))
 file.close()
 State.reset()
 State.load_game()
 check(State.return_position==Vector3.ZERO and State.hero.world_version==8,"Older outdoor saves move safely to town on the expanded map")
 check(State.active_classes()==roles and State.hero.points==points and State.hero.items.has("ether"),"Migration retains classes and skill points while adding new inventory defaults")
 check(FileAccess.file_exists(State.SAVE+".v3.backup"),"Schema-three original is backed up before migration")
 UserSettings.set_option("minimal_animations",false)
 await Sound.stop_all()
 get_tree().current_scene.queue_free()
 await settle()
 print("Adventure 0.8 checks: %s Failures: %s" % [checks,failures])
 get_tree().quit.call_deferred(1 if failures else 0)

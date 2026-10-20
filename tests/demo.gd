extends Node
var total=0
var failures=0
func check(value: bool, label: String):
 total+=1
 if value: print("PASS: ",label)
 else:
  failures+=1
  push_error(label)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func scene(path: String):
 get_tree().change_scene_to_file(path)
 await get_tree().process_frame
 await get_tree().process_frame
 return get_tree().current_scene
func dismiss(dialogue: Dialogue):
 var count=0
 while dialogue.active and count<30:
  dialogue.advance()
  count+=1
func kit(primary: String):
 State.new_adventure()
 State.create_hero("Aster",primary,1,2,1)
 for item in ["Iron Sword","Oak Shield",{"Paladin":"Steel Cuirass","Ranger":"Leather Vest","Druid":"Verdant Robe"}[primary]]:
  State.buy(item)
  State.equip(State.equipment_data[item].slot,item)
func tactical(sim: Combat) -> String:
 if sim.charging: return "Defend"
 if sim.h.hp<sim.stats.max_hp*0.55:
  if sim.h.potions>0: return "Items"
  if sim.regeneration==0 and sim.legal("Regrowth"): return "Regrowth"
 if sim.legal("Sacred Strike"): return "Sacred Strike"
 return "Sword Slash" if sim.legal("Sword Slash") else "Attack"
func fight(battle):
 var safety=0
 while battle.sim.outcome=="" and safety<100:
  battle.act(tactical(battle.sim))
  while battle.busy: await get_tree().process_frame
  safety+=1
 check(battle.sim.outcome=="Victory","Real battle victory: "+battle.sim.species)
func run():
 Engine.time_scale=8
 UserSettings.set_option("minimal_animations",true)
 for primary in State.classes:
  State.new_adventure()
  check(State.hero.primary=="" and State.hero.secondary.is_empty(),"New game has no preselected classes")
  check(State.hero.equipment.values().all(func(value): return value=="None") and State.hero.inventory.is_empty(),"New game starts with no equipped or owned equipment")
  check(State.create_hero("Aster",primary,1,2,1),"Character creation accepts "+primary)
  check(State.hero.secondary.size()==2 and not State.hero.secondary.has(primary),"Creation assigns distinct secondary classes")
  check(not State.equip("Weapon","Sunsteel Sword"),"Unowned equipment cannot be equipped")
  check(not State.buy("Sunsteel Sword") and State.hero.gold==120,"Unaffordable purchase does not spend gold")
  kit(primary)
  check(State.starter_ready() and State.hero.gold>=25,"Starter kit affordable for "+primary)
  var gold=State.hero.gold
  check(not State.buy("Iron Sword") and State.hero.gold==gold,"Duplicate purchase cannot spend gold")
  var sim=Combat.new(State.hero,State.stats())
  check(sim.legal("sword_slash") and sim.legal("shield_bash"),"Stable ability IDs and equipped techniques work")
  State.equip("Shield","None")
  check(not Combat.new(State.hero,State.stats()).legal("shield_bash"),"Shield Bash unavailable without shield")
  State.equip("Shield","Oak Shield")
  State.equip("Weapon","None")
  check(not Combat.new(State.hero,State.stats()).legal("sword_slash"),"Sword techniques unavailable unarmed")
  State.equip("Weapon","Iron Sword")
  State.hero.hp=35
  sim=Combat.new(State.hero,State.stats())
  var regrowth=sim.round_("regrowth")
  check(sim.regeneration==3 and regrowth.any(func(event): return event.text=="Regrowth"),"Regrowth applies a three-round heal-over-time")
  sim.round_("Defend")
  check(sim.regeneration==2 and sim.events.any(func(event): return event.text=="Regrowth · renewal"),"Regrowth ticks on following rounds")
  State.restore()
  sim=Combat.new(State.hero,State.stats())
  sim.round_("Defend")
  check(sim.nature_blessing>0,"Shield block primes data-defined class chemistry")
  sim.round_("Hunter's Mark")
  check(sim.nature_blessing==0 and sim.events.any(func(event): return event.text.contains("empowered")),"Ranger ability consumes nature blessing exactly once")
  check(not State.invest_skill(primary,"mythic"),"Advanced skills cannot bypass prerequisites/mastery")
  State.hero.points=20
  for node in ["oath","shield","light"]: State.invest_skill(primary,node)
  check(not State.invest_skill(primary,"mythic"),"Mythic requires independent class mastery")
  for index in range(3): State.reward(true)
  check(State.invest_skill(primary,"mythic") and State.can_mythic(primary),"Mastery and skill points together unlock primary mythic")
  var next: String=State.hero.secondary[0]
  State.set_primary(next)
  check(not State.can_mythic(primary) and State.hero.skills[primary].has("mythic"),"Class switch retains and disables old primary mythic")
  check(State.learn_weapon("sword","flow"),"Weapon mastery unlocks separate weapon tree")
  State.save_game()
  var owned=State.hero.inventory.duplicate()
  State.reset()
  State.load_game()
  check(State.hero.profile.name=="Aster" and State.hero.inventory==owned and State.hero.weapon_skills.sword.has("flow"),"New profile, inventory and separate progression survive reload")
 kit("Paladin")
 State.hero.hp=1
 State.hero.mp=0
 State.hero.companion.active=false
 var weak=Combat.new(State.hero,State.stats())
 check(weak.auto_resolve()=="Defeat","New-rule Auto-Battle can lose")
 kit("Paladin")
 var direct=Combat.new(State.hero,State.stats())
 var auto=Combat.new(State.hero,State.stats())
 auto.auto_resolve()
 while direct.outcome=="" and direct.turns<200:
  var action="Attack"
  if direct.h.hp<direct.stats.max_hp/2 and direct.legal("Regrowth"): action="Regrowth"
  elif direct.legal("Sacred Strike"): action="Sacred Strike"
  direct.round_(action)
 check(direct.h==auto.h and direct.enemy_hp==auto.enemy_hp,"New normal and Auto-Battle use identical deterministic rules")
 State.new_adventure()
 State.create_hero("Reserve","Paladin",0,0,0)
 check(State.buy("Steel Helm"),"Optional purchase allowed when starter funds remain")
 check(not State.buy("Steel Gauntlets") and not State.buy_potion(),"Starter reserve prevents spending essential equipment money")
 for item in ["Iron Sword","Oak Shield","Leather Vest"]:
  check(State.buy(item),"Reserved budget still buys essential equipment: "+item)
 # All six companion definitions have a functioning model and three combat behaviors.
 for id in State.companions:
  kit("Paladin")
  check(not State.choose_companion(id),"Permanent bond gated until intro completion: "+id)
  State.hero.journey.finished=true
  check(State.choose_companion(id),"Choose first companion: "+id)
  var other: String=State.companions.keys().filter(func(value): return value!=id)[0]
  check(not State.choose_companion(other),"Cannot choose second companion before postgame")
  var model=CompanionVisual.build(id)
  check(model.find_children("*","MeshInstance3D",true,false).size()>3,"Distinct companion model builds: "+id)
  model.free()
  check(State.train_companion("predator") and not State.train_companion("predator"),"Companion training spends points once")
  for behavior in ["Attack","Support","Defend"]:
   State.restore()
   State.hero.hp=65
   State.hero.companion.behavior=behavior
   var sim=Combat.new(State.hero,State.stats())
   sim.round_("Attack")
   check(sim.events.any(func(event): return event.actor=="Wolf"),id+" automated behavior: "+behavior)
  State.hero.companion.postgame_unlocked=true
  check(State.choose_companion(other),"Postgame permits second permanent companion")
  var third: String=State.companions.keys().filter(func(value): return value!=id and value!=other)[0]
  check(not State.choose_companion(third) and State.hero.companion.owned.size()==2,"Two-companion lifetime cap enforced")
  State.save_game()
  State.reset()
  State.load_game()
  check(State.hero.companion.owned.size()==2 and State.activate_companion(id),"Ownership, training records and active selection persist")
 # Actual new-player scene flow through creation, shop, guarded plants, dungeon and bond selection.
 State.new_adventure()
 var creator=await scene("res://scenes/create.tscn")
 creator.name_field.text="Rowan"
 creator.select_class("Druid")
 creator.begin()
 await get_tree().process_frame
 await get_tree().process_frame
 var world=get_tree().current_scene
 check(world.scene_file_path=="res://scenes/world.tscn" and State.hero.equipment.Weapon=="None","Creator enters village unequipped")
 world.hero.position=Vector3(3.5,0,1)
 world.interact()
 await get_tree().process_frame
 await get_tree().process_frame
 check(get_tree().current_scene.page=="shop","Visible outfitter opens shop page")
 for item in ["Iron Sword","Oak Shield","Verdant Robe"]:
  State.buy(item)
  State.equip(State.equipment_data[item].slot,item)
 get_tree().current_scene.leave()
 await get_tree().process_frame
 await get_tree().process_frame
 world=get_tree().current_scene
 world.hero.position=Vector3(-2.6,0,-0.8)
 world.interact()
 dismiss(world.dialogue)
 for i in range(3):
  world.hero.position=world.forest.herbs[i].position
  world.interact()
  await get_tree().process_frame
  await get_tree().process_frame
  var battle=get_tree().current_scene
  check(battle.scene_file_path=="res://scenes/battle.tscn","Moonleaf site has a visible encounter guard")
  await fight(battle)
  battle.return_to_adventure()
  await get_tree().process_frame
  await get_tree().process_frame
  world=get_tree().current_scene
  world.hero.position=world.forest.herbs[i].position
  world.interact()
 check(State.hero.exploration.herbs.size()==3 and State.hero.demo.field_guards.size()==3,"Guard victories unlock distinct Moonleaf gathering")
 world.hero.position=Vector3(-2.6,0,-0.8)
 world.interact()
 dismiss(world.dialogue)
 world.hero.position=Vector3(24,0,-12)
 world.interact()
 dismiss(world.dialogue)
 await get_tree().process_frame
 await get_tree().process_frame
 var dungeon=get_tree().current_scene
 check(dungeon.scene_file_path=="res://scenes/dungeon.tscn","New economy character enters sanctuary")
 dismiss(dungeon.dialogue)
 for i in range(2):
  dungeon.hero.position=dungeon.seals[i].position
  dungeon.interact()
  await get_tree().process_frame
  await get_tree().process_frame
  var battle=get_tree().current_scene
  await fight(battle)
  battle.return_to_adventure()
  await get_tree().process_frame
  await get_tree().process_frame
  dungeon=get_tree().current_scene
  dungeon.hero.position=dungeon.seals[i].position
  dungeon.interact()
  dismiss(dungeon.dialogue)
 dungeon.hero.position=dungeon.chest.position
 dungeon.interact()
 dismiss(dungeon.dialogue)
 dungeon.hero.position=Vector3(0,0,-27)
 dungeon.interact()
 dismiss(dungeon.dialogue)
 await get_tree().process_frame
 await get_tree().process_frame
 var boss=get_tree().current_scene
 await fight(boss)
 check(State.hero.journey.boss and State.owns("Sunsteel Sword"),"Boss grants an owned unique reward")
 boss.return_to_adventure()
 await get_tree().process_frame
 await get_tree().process_frame
 dungeon=get_tree().current_scene
 dungeon.hero.position=Vector3.ZERO
 dungeon.interact()
 await get_tree().process_frame
 await get_tree().process_frame
 world=get_tree().current_scene
 world.hero.position=Vector3(-2.6,0,-0.8)
 world.interact()
 dismiss(world.dialogue)
 await get_tree().process_frame
 await get_tree().process_frame
 check(State.hero.journey.finished and get_tree().current_scene.page=="companions","Quest ending opens permanent companion selection")
 check(State.choose_companion("spirit_fox"),"New player completes first permanent bond")
 State.save_game()
 State.reset()
 State.load_game()
 check(State.hero.journey.finished and State.hero.companion.current=="spirit_fox","Complete new demo progression survives reload")
 get_tree().current_scene.leave()
 await get_tree().process_frame
 await get_tree().process_frame
 world=get_tree().current_scene
 State.restore()
 world.hero.position=Vector3(0,0,5)
 world.show_board()
 State.enemy_id="warden"
 State.encounter_id=1000
 var echo=await scene("res://scenes/battle.tscn")
 await fight(echo)
 check(State.hero.demo.echo and State.hero.companion.postgame_unlocked,"Actual postgame echo victory unlocks second bond")
 check(State.choose_companion("golem") and not State.choose_companion("dragon"),"Postgame grants exactly one additional companion, not all six")
 State.save_game()
 State.reset()
 State.load_game()
 check(State.hero.companion.owned.size()==2 and State.hero.companion.current=="golem","Two permanent companions and postgame completion persist")
 UserSettings.set_option("minimal_animations",false)
 print("Demo checks: %s Failures: %s" % [total,failures])
 get_tree().quit(1 if failures else 0)

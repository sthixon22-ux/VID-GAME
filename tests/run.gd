extends Node
var failures=0
func check(value: bool, title: String):
 if value: print("PASS: ",title)
 else:
  failures+=1
  push_error(title)
func _ready():
 call_deferred("run")
func run():
 var state=get_node("/root/State")
 state.reset()
 var original=state.hero.duplicate(true)
 var s=state.stats()
 var a=Combat.new(original,s)
 var b=Combat.new(original,s)
 a.auto_resolve()
 while b.outcome=="":
  var action="Attack"
  if b.h.hp<s.max_hp/2 and b.h.mp>=8: action="Regrowth"
  elif b.h.mp>=7: action="Sacred Strike"
  b.round_(action)
 check(a.h==b.h and a.enemy_hp==b.enemy_hp,"Auto and normal rules produce identical seeded outcomes")
 check(a.outcome=="Victory" and a.h.mp<original.mp,"Starter hero wins and consumes MP")
 var weak=original.duplicate(true)
 weak.hp=1
 weak.mp=0
 weak.companion.active=false
 var lose=Combat.new(weak,{"attack":1,"defense":0,"speed":1,"max_hp":110,"max_mp":35})
 check(lose.auto_resolve()=="Defeat","Auto-Battle can lose")
 var mythic=original.duplicate(true)
 mythic.investments.Ranger=3
 var m=Combat.new(mythic,s)
 check(not m.legal("Wild Hunt"),"Secondary mythic unavailable despite saved investment")
 mythic.primary="Ranger"
 m=Combat.new(mythic,s)
 check(m.legal("Wild Hunt"),"Mythic available when its class becomes primary")
 state.hero.equipment.Weapon="Sunsteel Sword"
 check(state.stats().attack>s.attack,"Equipment changes derived stats")
 state.hero=original.duplicate(true)
 state.reward(false)
 check(state.hero.mastery==0,"Auto victories do not advance normal mastery")
 for i in range(10): state.reward(true)
 check(state.hero.mastery==10 and state.hero.level>1,"Normal wins unlock mastery and leveling")
 state.hero.investments.Ranger=3
 state.save_game()
 var saved=state.hero.duplicate(true)
 state.reset()
 state.load_game()
 check(state.hero==saved,"Save round trip preserves hero state")
 state.hero=original.duplicate(true)
 var world=load("res://scenes/world.tscn").instantiate()
 get_tree().root.add_child(world)
 await get_tree().process_frame
 world.refresh_menu()
 check(world.goblins.size()==3,"Forest scene starts with visible encounters")
 check(not world.forest.can_walk(Vector3(12,0,0)) and world.forest.can_walk(Vector3(12,0,-12)),"Stream blocks movement except at the bridge")
 check(not world.forest.can_walk(Vector3(-7,0,5)),"Village houses block movement")
 for herb in world.forest.herbs:
  world.hero.position=herb.position
  world.interact()
 check(state.hero.exploration.herbs.size()==3,"Three distinct Moonleaf plants can be gathered")
 var potions=state.hero.potions
 world.interact()
 check(state.hero.potions==potions,"Gathered herb cannot reward twice")
 world.hero.position=Vector3(-2.6,0,-0.8)
 var gold=state.hero.gold
 world.interact()
 check(state.hero.exploration.quest_done and state.hero.gold==gold+60,"Mira completes the herb quest and awards gold")
 world.interact()
 check(state.hero.gold==gold+60,"Completed quest cannot reward twice")
 world.hero.position=Vector3(24,0,-12)
 world.interact()
 check(state.hero.exploration.shrine and state.hero.gold==gold+90,"Shrine discovery grants a one-time reward")
 world.interact()
 check(state.hero.gold==gold+90,"Shrine cannot reward twice")
 state.save_game()
 state.reset()
 state.load_game()
 check(state.hero.exploration.quest_done and state.hero.exploration.herbs.size()==3,"Exploration progress survives save/load")
 world.hero.position=world.goblins[0].position
 world.encounter(true)
 check(world.message.contains("10 normal"),"Exploration blocks auto before mastery")
 state.hero.mastery=10
 world.encounter(true)
 check(world.message.contains("Auto:"),"Exploration resolves auto without battle scene")
 check(not world.goblins[state.encounter_id].visible or state.cleared_until.has(state.encounter_id),"Auto victory starts encounter respawn cooldown")
 world.queue_free()
 await get_tree().process_frame
 state.hero=original.duplicate(true)
 var battle=load("res://scenes/battle.tscn").instantiate()
 get_tree().root.add_child(battle)
 await get_tree().process_frame
 battle.submenu(["Regrowth","Sacred Strike"])
 battle.companion_menu()
 battle.main_menu()
 battle.sim.enemy_hp=1
 battle.act("Attack")
 await get_tree().create_timer(2.0).timeout
 check(battle.sim.outcome=="Victory" and state.hero.mastery==1,"Battle presentation completes and awards normal victory")
 battle.queue_free()
 state.hero=original
 state.save_game()
 print("Failures: ",failures)
 get_tree().quit(1 if failures else 0)

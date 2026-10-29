extends Node
var checks=0
var failures=0
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func run():
 Engine.time_scale=12
 UserSettings.set_option("muted",true);UserSettings.set_option("minimal_animations",false);UserSettings.set_option("battle_speed",2.5)
 State.new_adventure();State.create_hero("Ash","Barbarian",0,0,0,["Wizard","Healer"],"Male")
 State.hero.level=12;State.hero.journey.region="ironroot";State.hero.journey.finished=true;State.choose_companion("dragon")
 State.grant_item("Wyrmspine Greatblade");State.equip("Weapon","Wyrmspine Greatblade");State.grant_item("Oathkeeper Plate");State.equip("Chest","Oathkeeper Plate")
 for c in State.classes:State.hero.skills[c]=State.classes[c].nodes.map(func(n):return n.id)
 for family in State.weapon_trees:State.hero.weapon_skills[family]=State.weapon_trees[family].map(func(n):return n.id)
 for species in ["forge_sentinel","crag_hound","storm_roc","ironroot_colossus"]:
  State.enemy_id=species
  get_tree().change_scene_to_file("res://scenes/battle.tscn")
  for i in 8:await get_tree().process_frame
  var battle=get_tree().current_scene
  battle.sim.enemy_hp=999999;battle.sim.enemy.hp=999999;battle.sim.h.hp=99999;battle.sim.stats.max_hp=99999
  for n in 10:
   battle.sim.h.mp=999; battle.sim.h.hp=99999
   var action=["Sundering Roar","Attack","Arcane Bolt","Healing Light"][n%4]
   if not battle.sim.legal(action):action="Attack"
   await battle.act(action)
   checks+=1
   if battle.busy or not is_instance_valid(battle.actors.Goblin):failures+=1
  # Queue a transition with live VFX to exercise safe engine cleanup.
  battle.return_to_adventure()
  for i in 8:await get_tree().process_frame
 var last=get_tree().current_scene;get_tree().current_scene=null;last.queue_free()
 for i in 8:await get_tree().process_frame
 print("Ironroot animated combat checks: %s Failures: %s" % [checks,failures])
 await Sound.stop_all();get_tree().quit(1 if failures else 0)

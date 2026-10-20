extends Node
var checks=0
var failures=0
func check(value: bool, label: String):
 checks+=1
 if value: print("PASS: ",label)
 else:
  failures+=1
  push_error(label)
func raw(path: String, text: String):
 var file=FileAccess.open(path,FileAccess.WRITE)
 file.store_string(text)
 file.close()
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func run():
 State.reset()
 var path="user://reliability.json"
 for suffix in ["",".previous",".tmp",".v0.backup"]: DirAccess.remove_absolute(path+suffix)
 raw(path,JSON.stringify(State.hero))
 check(SaveStore.load_hero(path).hero.level==1,"Legacy flat save loads")
 check(FileAccess.file_exists(path+".v0.backup"),"Legacy original backed up")
 State.hero.gold=123
 State.remember_position(Vector3(1.25,0,-2.75))
 check(SaveStore.write_hero(State.hero,path),"Validated versioned save writes")
 check(SaveStore.inspect(path).hero.save_schema_version==SaveStore.VERSION,"Schema metadata stored")
 check(SaveStore.inspect(path).hero.journey.position[0]==1.25,"Fractional position preserved")
 raw(path,"{truncated")
 var recovered=SaveStore.load_hero(path)
 check(not recovered.blocked and recovered.hero.gold==0 and not recovered.notice.is_empty(),"Corruption recovers previous complete save")
 check(SaveStore.write_hero(State.hero,path),"Recovered save can be replaced safely")
 check(SaveStore.inspect(path+".previous").hero.gold==0,"Corrupt primary does not overwrite backup")
 var future=State.hero.duplicate(true)
 future.save_schema_version=999
 raw(path,JSON.stringify(future))
 var original=FileAccess.get_file_as_string(path)
 check(SaveStore.load_hero(path).blocked,"Future schema blocks loading")
 check(not SaveStore.write_hero(State.hero,path) and FileAccess.get_file_as_string(path)==original,"Future save cannot be overwritten")
 DirAccess.remove_absolute(path+".previous")
 raw(path,"broken")
 check(SaveStore.load_hero(path).blocked,"Unrecoverable corruption blocks implicit reset")
 var moved=ExplorationMotion.move(Vector3.ZERO,Vector3(10,0,0),func(pos): return pos.x<2 or pos.x>3)
 check(moved.x<2,"Long frames cannot tunnel through narrow barriers")
 var slide=ExplorationMotion.move(Vector3.ZERO,Vector3(4,0,4),func(pos): return pos.x<2)
 check(slide.x<2 and slide.z>3.9,"Blocked movement slides along obstacle")
 var arena=Node3D.new()
 add_child(arena)
 CameraObstacles.box(arena,Vector3(0,1,4),Vector3(4,4,1))
 var camera=ExplorationCamera.new()
 arena.add_child(camera)
 await get_tree().physics_frame
 await get_tree().physics_frame
 camera.update_view(Vector3(0,1,0),Vector3(0,0,8),0.1)
 check(camera.distance<3.5 and camera.distance>2.8,"Camera sphere sweep stops before wall")
 camera.update_view(Vector3(0,1,0),Vector3(8,0,0),1.0)
 check(camera.distance>7,"Camera eases outward after obstruction clears")
 arena.queue_free()
 UserSettings.set_option("battle_speed",2.5)
 UserSettings.set_option("minimal_animations",true)
 UserSettings.reload()
 check(UserSettings.battle_speed==2.5 and UserSettings.minimal_animations,"Presentation settings persist")
 check(is_equal_approx(UserSettings.duration(1),0.4) and Engine.time_scale==1,"Presentation clock leaves engine time unchanged")
 State.reset()
 var reference=Combat.new(State.hero,State.stats())
 reference.round_("Sacred Strike")
 State.enemy_id="goblin"
 get_tree().change_scene_to_file("res://scenes/battle.tscn")
 await get_tree().process_frame
 await get_tree().process_frame
 var battle=get_tree().current_scene
 battle.options.open()
 battle.act("Attack")
 check(battle.sim.turns==0,"Modal settings block battle actions")
 battle.options.close()
 battle.act("Sacred Strike")
 while battle.busy: await get_tree().process_frame
 check(battle.sim.h==reference.h and battle.sim.enemy_hp==reference.enemy_hp and battle.sim.wolf_hp==reference.wolf_hp,"Minimal fast presentation matches pure combat state")
 UserSettings.set_option("minimal_animations",false)
 UserSettings.set_option("battle_speed",1.0)
 battle.queue_free()
 await get_tree().process_frame
 print("Reliability: %s checks, %s failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)

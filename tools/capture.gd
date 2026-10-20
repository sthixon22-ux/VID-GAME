extends Node
var output="/tmp/verdant-oath-captures"
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func shot(name_: String):
 await get_tree().create_timer(0.5).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join(name_+".png"))
 print("Captured: ",name_)
func change(path: String):
 get_tree().change_scene_to_file(path)
 await get_tree().process_frame
 await get_tree().process_frame
 return get_tree().current_scene
func run():
 if DisplayServer.get_name()=="headless":
  push_error("Capture requires a display and renderer")
  get_tree().quit(1)
  return
 if not OS.get_cmdline_user_args().is_empty(): output=OS.get_cmdline_user_args()[0]
 DirAccess.make_dir_recursive_absolute(output)
 State.reset()
 await change("res://scenes/title.tscn")
 await shot("title")
 var world=await change("res://scenes/world.tscn")
 await shot("village")
 world.hero.position=Vector3(-2.6,0,-0.8)
 world.interact()
 await shot("dialogue")
 State.return_position=Vector3(0,0,-24)
 State.hero.journey.entered=true
 State.hero.journey.region="dungeon"
 await change("res://scenes/dungeon.tscn")
 await shot("dungeon")
 State.enemy_id="warden"
 await change("res://scenes/battle.tscn")
 await shot("boss")
 await Sound.stop_all()
 get_tree().quit()

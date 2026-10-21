extends Node
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute("/tmp/verdant-creation-skins")
 State.new_adventure()
 get_tree().change_scene_to_file("res://scenes/create.tscn")
 for i in range(4):await get_tree().process_frame
 var creator=get_tree().current_scene
 for sex in ["Male","Female"]:
  creator.select_class("Paladin")
  creator.select_sex(sex)
  await get_tree().create_timer(.3).timeout
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("/tmp/verdant-creation-skins/create_"+sex.to_lower()+".png")
 creator.select_sex("Male")
 creator.name_field.text="Aster"
 creator.begin()
 await get_tree().create_timer(.5).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("/tmp/verdant-creation-skins/male_in_game.png")
 print("Creation and in-game male captures complete")
 await Sound.stop_all()
 get_tree().quit()

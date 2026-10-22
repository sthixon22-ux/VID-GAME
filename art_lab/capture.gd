extends Node
var output="/tmp/verdant-art-lab"
var lab:Control
func _ready():
 if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0]
 DirAccess.make_dir_recursive_absolute(output)
 call_deferred("run")
func shot(label:String):
 for i in range(5):await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join(label+".png"))
 print("Captured ",label)
func run():
 lab=load("res://art_lab/comparison.tscn").instantiate()
 add_child(lab)
 await shot("characters_idle")
 for motion in ArtLabActor.MOTIONS:
  lab.set_motion(motion)
  for actor in lab.actors:actor.seek_motion(.3)
  if lab.playing:lab.toggle_play()
  await shot("motion_"+motion.to_lower().replace(" ","_"))
 lab.actors[1].toggle_outfit_part("_Head_Hood")
 lab.actors[1].toggle_outfit_part("_Acc_Pauldrons")
 await shot("outfit_parts")
 lab.actors[1].toggle_outfit_part("_Head_Hood")
 lab.actors[1].toggle_outfit_part("_Acc_Pauldrons")
 lab.select_outfit(1)
 await shot("outfit_peasant")
 lab.select_outfit(0)
 lab.set_motion("Idle")
 lab.set_camera_view(4)
 for expression in ["neutral","happy","angry","blink"]:
  lab.select_expression(lab.FACES.find(expression))
  await shot("face_"+expression)
 lab.select_expression(0)
 lab.select_vrm_sample(1)
 lab.set_camera_positions()
 await shot("face_twist_sample")
 lab.select_vrm_sample(0)
 lab.set_camera_view(1)
 lab.set_mode("Wolf comparison")
 lab.set_motion("Walking")
 if not lab.playing:lab.toggle_play()
 await shot("wolf_comparison")
 lab.set_mode("Goblin audit")
 await shot("goblin_audit")
 lab.queue_free()
 for i in range(4):await get_tree().process_frame
 get_tree().quit()

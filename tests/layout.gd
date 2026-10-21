extends Node
var checks=0
var failures=0
func check(value: bool, label: String):
 checks+=1
 if value: print("PASS: ",label)
 else:
  failures+=1
  push_error(label)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func settle():
 for index in range(8): await get_tree().process_frame
func run():
 State.new_adventure()
 State.save_game()
 State.save_notice="Progression updated: skills reset to 4 unspent points for the point-based trees. Previous investments are archived; level, quests, equipment and companions are kept."
 get_tree().change_scene_to_file("res://scenes/title.tscn")
 await settle()
 var title=get_tree().current_scene
 var panel: PanelContainer=title.menu.get_parent().get_parent()
 check(panel.size.x<=501 and panel.position.x+panel.size.x<=1280,"Long migration notice cannot stretch title panel offscreen")
 var notice: Label
 for child in title.menu.get_children():
  if child is Label and child.text==State.save_notice: notice=child
 check(notice!=null and notice.get_line_count()>1 and notice.size.x<=472,"Migration notice wraps within the menu")
 check(panel.size.y<=511 and panel.position.y+panel.size.y<=720,"Overflow stays in the vertical scroll area")
 if DisplayServer.get_name()!="headless" and not OS.get_cmdline_user_args().is_empty():
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
 State.save_notice="This save needs a newer game version. It has been preserved. ".repeat(10)
 title.main_menu()
 await settle()
 check(panel.size.x<=501 and panel.size.y<=511,"Long error notices also preserve menu bounds")
 title.confirm_new()
 await settle()
 check(panel.size.x<=501,"New-game confirmation stays within title bounds")
 State.save_notice=""
 title.main_menu()
 await settle()
 check(panel.size.x<=501,"Normal title menu remains bounded")
 print("Layout checks: %s Failures: %s" % [checks,failures])
 await Sound.stop_all()
 title.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 get_tree().quit(1 if failures else 0)

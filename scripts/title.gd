extends Node3D
var menu: VBoxContainer
var clock=0.0
func _ready():
 Art.environment_(self)
 for i in range(16): Art.tree(self,Vector3(sin(i*1.9)*14,0,cos(i*1.9)*14),1.2)
 var hero=Art.actor("Hero",State.hero.equipment)
 add_child(hero)
 hero.position=Vector3(-0.8,0,0)
 hero.rotation.y=-0.3
 var wolf=Art.actor("Wolf")
 add_child(wolf)
 wolf.position=Vector3(0.8,0,0.6)
 var camera=Camera3D.new()
 add_child(camera)
 camera.position=Vector3(3,2.8,6)
 camera.look_at(Vector3(0,1,0))
 camera.current=true
 menu=UI.panel(self,Vector2(70,90),Vector2(500,510))
 Sound.theme_("woodland")
 main_menu()
func clear():
 for c in menu.get_children():
  menu.remove_child(c)
  c.queue_free()
func main_menu():
 clear()
 var title=UI.label(menu,"VERDANT OATH")
 title.add_theme_font_size_override("font_size",36)
 UI.label(menu,"The Bell Beneath the Woods\nAdventure milestone 0.4\n")
 UI.button(menu,"Continue adventure",func(): get_tree().change_scene_to_file(State.travel_scene()))
 UI.button(menu,"New adventure",confirm_new)
 UI.button(menu,"Music / sound: %s" % ("Off" if Sound.muted else "On"),func():
  Sound.toggle()
  main_menu())
 UI.label(menu,"\nWASD move · Right mouse orbit · E interact\nShift sprint · Escape menu\n\nA short original turn-based fantasy adventure.")
func confirm_new():
 clear()
 UI.label(menu,"Begin a new adventure?\nYour current save will be copied to hero.backup.json.")
 UI.button(menu,"Start new adventure",func():
  if FileAccess.file_exists(State.SAVE): DirAccess.copy_absolute(State.SAVE,"user://hero.backup.json")
  State.reset()
  State.return_position=Vector3.ZERO
  State.cleared_until.clear()
  State.enemy_id="goblin"
  State.save_game()
  get_tree().change_scene_to_file("res://scenes/world.tscn"))
 UI.button(menu,"Back",main_menu)

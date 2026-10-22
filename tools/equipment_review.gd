extends Node3D
var output="/tmp/verdant-equipment-review"
func _ready():call_deferred("run")
func shot(name_:String):
 await get_tree().create_timer(.15).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join(name_+".png"))
 print("Captured ",name_)
func run():
 DirAccess.make_dir_recursive_absolute(output)
 Art.studio(self)
 var cam=Camera3D.new();add_child(cam)
 cam.position=Vector3(-2.8,1.7,-3.6)
 cam.look_at(Vector3(0,1.0,0));cam.current=true;cam.fov=35
 for sex in ["Male","Female"]:
  for chest in WardrobeVisual.CHESTS:
   var hero=HeroVisual.new({"Weapon":"None","Shield":"None","Chest":chest},{"class":"Paladin","sex":sex})
   add_child(hero)
   await shot(sex+"_"+chest.replace("'","").replace(" ","_"))
   hero.queue_free();await get_tree().process_frame
 for family in ["sword","greatsword","axe","hammer","spear","bow","staff","dagger"]:
  var item=""
  for name_ in State.equipment_data:
   if State.equipment_data[name_].get("weapon_type")==family:item=name_;break
  var hero=HeroVisual.new({"Weapon":item,"Shield":"None","Chest":"Leather Vest"},{"class":"Warrior","sex":"Male"})
  hero.battle=true;add_child(hero)
  await shot(family+"_stance")
  hero.play_action("Attack")
  await get_tree().create_timer(hero.action_duration*.45).timeout
  # Pause the authored player and procedural action at this phase for a readable capture.
  hero.player.pause()
  hero.set_process(false)
  await shot(family+"_attack")
  print("Grip ",family," right ",hero.pose_modifier.grip_error," left ",hero.pose_modifier.left_error)
  hero.queue_free();await get_tree().process_frame
 get_tree().quit()

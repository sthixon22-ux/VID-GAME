extends Node3D
var hero:HeroVisual
func _ready():call_deferred("run")
func run():
 Art.environment_(self)
 Art.box(self,Vector3(0,-.08,0),Vector3(12,.1,12),Color("566878"))
 var camera=Camera3D.new()
 add_child(camera)
 camera.fov=30
 camera.position=Vector3(1.1,1.25,3)
 camera.look_at(Vector3(0,.95,0))
 var output="/tmp/quaternius-hero"
 DirAccess.make_dir_recursive_absolute(output)
 var samples={
 "ranger":{"Weapon":"Iron Sword","Shield":"Oak Shield","Chest":"Leather Vest","Helmet":"Ranger Hood"},
 "steel":{"Weapon":"Moonleaf Saber","Shield":"Dawn Kite Shield","Chest":"Steel Cuirass","Helmet":"Steel Helm","Gauntlets":"Steel Gauntlets","Pants":"Steel Greaves","Boots":"Steel Sabatons"},
 "traveler":{"Weapon":"None","Shield":"None","Chest":"None"},
 "staff":{"Weapon":"Oak Staff","Shield":"None","Chest":"Verdant Robe"}}
 for id in samples:
  if hero:hero.free()
  hero=HeroVisual.new(samples[id],{"dye":1})
  add_child(hero)
  hero.rotation.y=PI
  await get_tree().create_timer(.3).timeout
  await shot(output,id)
  if id=="ranger":
   for action in ["Sword Slash","Shield raised","Regrowth","Defeat"]:
    hero.play_action(action)
    await get_tree().create_timer(.12).timeout
    hero.player.seek(hero.player.get_animation(hero.player.current_animation).length*.45,true)
    hero.player.pause()
    await shot(output,action.replace(" ","_"))
 get_tree().quit()
func shot(output:String,id:String):
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))
 print("Captured hero ",id)

extends Node
var output="/tmp/verdant-world-review"
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func change(path:String):
 get_tree().change_scene_to_file(path)
 for i in 6:await get_tree().process_frame
 return get_tree().current_scene
func shot(label:String):
 await get_tree().create_timer(.3).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join(label+".png"))
 print("Captured ",label)
func run():
 UserSettings.set_option("muted",true)
 DirAccess.make_dir_recursive_absolute(output)
 State.new_adventure();State.create_hero("Aster","Ranger",0,0,0,["Druid","Paladin"],"Female")
 State.shop_id="willowbrook";State.buy("Iron Sword");State.equip("Weapon","Iron Sword")
 State.hero.journey.region="forest";State.remember_position(Vector3(0,0,0))
 var world=await change("res://scenes/world.tscn")
 world.contact_grace=999
 await shot("willowbrook")
 world.hero.position=Vector3(-4,0,-34)
 await shot("woodland")
 State.hero.journey.finished=true;State.choose_companion("spirit_fox")
 State.hero.journey.region="mirefen";State.remember_position(Vector3(0,0,-19))
 var marsh=await change("res://scenes/mirefen.tscn");marsh.grace=999
 await shot("marsh")
 for region in TownServices.DOORS:
  for door in TownServices.DOORS[region]:
   TownServices.enter(get_tree(),region,door)
   for i in 6:await get_tree().process_frame
   var interior=get_tree().current_scene
   interior.hero.position=Vector3(0,0,1)
   await shot(region+"_"+door[1])
 var last=get_tree().current_scene
 get_tree().current_scene=null
 last.queue_free()
 for i in 8:await get_tree().process_frame
 await Sound.stop_all()
 get_tree().quit()

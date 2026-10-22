extends Node
var output="/tmp/verdant-companion-game"
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func change(path:String):
 get_tree().change_scene_to_file(path)
 for i in range(4):await get_tree().process_frame
 return get_tree().current_scene
func shot(name_:String):
 await get_tree().create_timer(.2).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join(name_+".png"))
 print("Captured in-game ",name_)
func run():
 DirAccess.make_dir_recursive_absolute(output)
 Engine.time_scale=2
 for id in State.companions:
  State.new_adventure()
  State.create_hero("Aster","Paladin",0,0,0,["Ranger","Druid"],"Female")
  for item in ["Iron Sword","Traveler's Clothing"]:
   State.buy(item)
   State.equip(State.equipment_data[item].slot,item)
  State.hero.journey.finished=true
  State.choose_companion(id)
  State.menu_page="companions"
  var menu=await change("res://scenes/character.tscn")
  menu.pending_companion=id
  menu.show_page("companions")
  await shot("menu_"+id)
  var world=await change("res://scenes/world.tscn")
  world.contact_grace=999
  world.yaw=-.4
  await shot("world_"+id)
  State.enemy_id="goblin"
  var battle=await change("res://scenes/battle.tscn")
  battle.act("Defend")
  var frames=0
  while battle.actors.Wolf.last_action.is_empty() and battle.busy and frames<180:
   frames+=1
   await get_tree().process_frame
  var pet=battle.actors.Wolf
  if not pet.player.current_animation.is_empty():
   pet.player.seek(pet.player.get_animation(pet.player.current_animation).length*.5,true)
   pet.player.pause()
   pet.action_remaining=99
  await shot("battle_"+id)
  while battle.busy:await get_tree().process_frame
 await Sound.stop_all()
 get_tree().quit()

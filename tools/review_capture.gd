extends Node
var out="/tmp/demo9-review"
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func settle():
 for i in range(10):await get_tree().process_frame
func shot(name_:String):
 await get_tree().create_timer(.3).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(out.path_join(name_+".png"))
 print("Captured ",name_)
func scene(path:String):
 get_tree().change_scene_to_file(path)
 await settle()
 return get_tree().current_scene
func run():
 if not OS.get_cmdline_user_args().is_empty():out=OS.get_cmdline_user_args()[0]
 DirAccess.make_dir_recursive_absolute(out)
 State.new_adventure()
 await scene("res://scenes/create.tscn")
 await shot("creation")
 State.create_hero("Aster","Paladin",0,0,1,["Ranger","Druid"])
 for item in ["Iron Sword","Traveler's Clothing","Traveler's Pendant"]:
  State.buy(item)
  State.equip(State.equipment_data[item].slot,item)
 State.menu_page="equipment"
 var menu=await scene("res://scenes/character.tscn")
 await shot("armor")
 menu.show_page("shop")
 for item in ["Iron Sword","Twin Daggers","Oak Staff","Traveler's Clothing","Traveler's Pendant"]:
  menu.preview_shop_weapon(item)
  await shot("shop_"+item.replace(" ","_"))
 menu.preview_supply("ether")
 await shot("shop_ether")
 menu.show_page("inventory")
 await shot("inventory")
 menu.companion_tree_id="dragon"
 menu.show_page("companion_tree")
 await shot("companion_tree")
 var world=await scene("res://scenes/world.tscn")
 world.contact_grace=999
 await shot("town")
 world.hero.position=Vector3(-3,0,-37)
 world.yaw=-.2
 await get_tree().create_timer(.4).timeout
 await shot("woods")
 world.hero.position=Vector3(37,0,-54)
 world.yaw=-1.3
 await get_tree().create_timer(.4).timeout
 await shot("plains")
 State.enemy_id="goblin"
 var battle=await scene("res://scenes/battle.tscn")
 await shot("battle")
 battle.act("Sword Slash")
 await get_tree().create_timer(.25).timeout
 await shot("battle_attack")
 while battle.busy:await get_tree().process_frame
 State.hero.journey.region="dungeon"
 State.hero.journey.entered=true
 State.remember_position(Vector3(0,0,-10))
 var dungeon=await scene("res://scenes/dungeon.tscn")
 dungeon.contact_grace=999
 await shot("dungeon")
 dungeon.open_puzzle(0)
 await shot("dials")
 dungeon.puzzle_panel.get_parent().get_parent().hide()
 dungeon.open_puzzle(1)
 await shot("bells")
 State.menu_page="companions"
 menu=await scene("res://scenes/character.tscn")
 for id in State.companions:
  menu.pending_companion=id
  menu.show_page("companions")
  await shot(id)
 await Sound.stop_all()
 get_tree().current_scene.queue_free()
 await settle()
 get_tree().quit()

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
 State.new_adventure()
 await change("res://scenes/title.tscn")
 await shot("title")
 get_tree().current_scene.options.open()
 await shot("settings")
 get_tree().current_scene.options.close()
 var creator=await change("res://scenes/create.tscn")
 await shot("creation")
 creator.name_field.text="Rowan"
 creator.skin=1
 creator.hair=2
 creator.dye=1
 creator.update_preview()
 creator.begin()
 await get_tree().process_frame
 await get_tree().process_frame
 await shot("unequipped")
 State.menu_page="shop"
 await change("res://scenes/character.tscn")
 await shot("shop")
 for item in ["Iron Sword","Oak Shield","Steel Cuirass"]:
  State.buy(item)
  State.equip(State.equipment_data[item].slot,item)
 var world=await change("res://scenes/world.tscn")
 await shot("village")
 world.hero.position=Vector3(-2.6,0,-0.8)
 world.interact()
 await shot("dialogue")
 State.menu_page="equipment"
 await change("res://scenes/character.tscn")
 await shot("equipment")
 State.menu_page="skills"
 await change("res://scenes/character.tscn")
 await shot("skills")
 State.menu_page="weapons"
 await change("res://scenes/character.tscn")
 await shot("weapons")
 State.menu_page="journal"
 await change("res://scenes/character.tscn")
 await shot("journal")
 State.return_position=Vector3(0,0,-24)
 State.hero.journey.entered=true
 State.hero.journey.region="dungeon"
 await change("res://scenes/dungeon.tscn")
 await shot("dungeon")
 State.enemy_id="warden"
 await change("res://scenes/battle.tscn")
 await shot("boss")
 var battle=get_tree().current_scene
 battle.act("Sacred Strike")
 await get_tree().create_timer(1.3).timeout
 await shot("sacred_strike")
 while battle.busy: await get_tree().process_frame
 State.hero.journey.finished=true
 State.hero.journey.region="forest"
 State.menu_page="companions"
 var bonds=await change("res://scenes/character.tscn")
 bonds.pending_companion="griffin"
 bonds.show_page("companions")
 await shot("companion_choice")
 State.choose_companion("spirit_fox")
 bonds.pending_companion=""
 bonds.show_page("companions")
 await shot("companion_training")
 State.return_position=Vector3.ZERO
 world=await change("res://scenes/world.tscn")
 await shot("fox_following")
 State.hero.mastery=10
 world.hero.position=world.goblins[0].position
 world.encounter(true)
 await shot("auto_risk")
 world.auto_panel.resolve()
 await shot("auto_results")
 await Sound.stop_all()
 get_tree().quit()

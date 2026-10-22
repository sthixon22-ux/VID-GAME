extends Node
var output="/tmp/mirefen-review"
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func change(path:String):
 get_tree().change_scene_to_file(path)
 for i in 6:await get_tree().process_frame
 var node=get_tree().current_scene
 if "grace" in node:node.grace=999
 return node
func shot(label:String):
 await get_tree().create_timer(.5).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join(label+".png"))
 print("Captured ",label)
func run():
 DirAccess.make_dir_recursive_absolute(output)
 State.new_adventure()
 State.create_hero("Aster","Druid",0,0,0,["Ranger","Healer"],"Female")
 State.buy("Oak Staff");State.equip("Weapon","Oak Staff")
 State.hero.journey.finished=true
 State.choose_companion("spirit_fox")
 State.hero.journey.region="mirefen"
 State.remember_position(Vector3(0,0,4))
 var marsh=await change("res://scenes/mirefen.tscn")
 marsh.yaw=.4
 await shot("reedcross")
 marsh.hero.position=marsh.ROYAL
 marsh.interact()
 await shot("aldren")
 while marsh.dialogue.active:marsh.dialogue.advance()
 marsh.hero.position=Vector3(0,0,-33)
 marsh.yaw=.6
 await shot("causeway")
 State.shop_id="reedcross_weapons"
 State.menu_page="shop"
 await change("res://scenes/character.tscn")
 await shot("weapon_shop")
 State.hero.campaign.sluice_key=true
 State.hero.journey.region="reliquary"
 State.remember_position(Vector3(0,0,-13))
 var dungeon=await change("res://scenes/reliquary.tscn")
 await shot("reliquary_flooded")
 dungeon.hero.position=dungeon.WEST
 dungeon.interact()
 await get_tree().create_timer(1.6).timeout
 await shot("reliquary_drained")
 dungeon.hero.position=dungeon.EAST
 dungeon.interact()
 dungeon.hero.position=Vector3(0,0,-37)
 await shot("reliquary_heart")
 State.enemy_id="reliquary_keeper"
 State.encounter_id=2300
 var battle=await change("res://scenes/battle.tscn")
 await shot("keeper")
 await battle.act("Defend")
 await shot("keeper_telegraph")
 get_tree().quit()

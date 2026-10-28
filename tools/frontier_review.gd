extends Node
const OUTPUT="/tmp/verdant-frontier-review"
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func change(path:String):
 get_tree().change_scene_to_file(path)
 for i in 8:await get_tree().process_frame
 return get_tree().current_scene
func shot(name_:String):
 await get_tree().create_timer(.3).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(OUTPUT.path_join(name_+".png"));print("Captured ",name_)
func run():
 UserSettings.set_option("muted",true)
 DirAccess.make_dir_recursive_absolute(OUTPUT)
 State.new_adventure();State.create_hero("Ash","Warrior",0,0,0,["Assassin","Druid"],"Male")
 State.hero.journey.finished=true;State.hero.journey.entered=true;State.hero.campaign.reported=true
 State.grant_item("Sahir Sword");State.equip("Weapon","Sahir Sword");State.grant_item("Sunveil Coat");State.equip("Chest","Sunveil Coat")
 State.choose_companion("dire_wolf");State.restore()
 for region in ["sahir","kharholt"]:
  State.hero.journey.region=region;State.remember_position(Vector3(0,0,10))
  var area=await change(ExpeditionRules.scene(region));area.grace=999
  await shot(region+"_town")
  area.hero.position=area.targets()[0]+Vector3(0,0,4)
  await shot(region+"_wilds")
  var p=ExpeditionRules.progress(State.hero);p.mirrors=[1,3,2];p.lifts=["west","east"];p.briefed=["sahir","kharholt"]
  State.hero.journey.region=ExpeditionRules.regions[region].dungeon;State.remember_position(Vector3(0,0,-18))
  area=await change(ExpeditionRules.scene(State.hero.journey.region));area.grace=999
  await shot(region+"_dungeon")
  area.set_process(false);area.camera.position=Vector3(30,44,29);area.camera.look_at(Vector3(0,0,-18));area.camera.far=150
  await shot(region+"_layout")
 for enemy in ["warden","reliquary_keeper","glass_sentinel","ironroot_colossus"]:
  State.enemy_id=enemy
  var battle=await change("res://scenes/battle.tscn")
  await shot(enemy+"_boss")
 State.hero.journey.region="dungeon";State.remember_position(Vector3(0,0,-10))
 var old=await change("res://scenes/dungeon.tscn");old.contact_grace=999
 old.set_process(false);old.camera.position=Vector3(29,41,24);old.camera.look_at(Vector3(0,0,-15))
 await shot("sanctuary_layout")
 State.hero.journey.region="reliquary";State.hero.campaign.reliquary_west=true;State.remember_position(Vector3(0,0,-15))
 old=await change("res://scenes/reliquary.tscn");old.grace=999
 old.set_process(false);old.camera.position=Vector3(34,45,23);old.camera.look_at(Vector3(0,0,-21))
 await shot("reliquary_layout")
 var last=get_tree().current_scene;get_tree().current_scene=null;last.queue_free()
 for i in 8:await get_tree().process_frame
 await Sound.stop_all();get_tree().quit()

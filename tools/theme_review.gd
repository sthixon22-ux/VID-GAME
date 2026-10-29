extends Node3D
const OUTPUT="/tmp/verdant-theme-review"
var camera:Camera3D
func _ready():call_deferred("run")
func shot(label:String):
 await get_tree().create_timer(.25).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(OUTPUT.path_join(label+".png"));print("Captured ",label)
func run():
 UserSettings.set_option("muted",true)
 DirAccess.make_dir_recursive_absolute(OUTPUT)
 Art.studio(self)
 camera=Camera3D.new();add_child(camera);camera.position=Vector3(-2.7,1.8,-3.6);camera.look_at(Vector3(0,1,0));camera.current=true;camera.fov=35
 for sex in ["Male","Female"]:
  for armor in ["Knight’s Harness","Runewoven Robe","Shadowstalker Leathers","Wildheart Mantle","Sunpriest Vestments","Wayfarer’s Wraps"]:
   var model=HeroVisual.new({"Weapon":"None","Chest":armor,"Shield":"None"},{"sex":sex,"class":"Barbarian"});add_child(model)
   await shot(sex+"_"+State.equipment_data[armor].id);model.queue_free();await get_tree().process_frame
 for weapon in ["Flamebrand","Dragonbone Greatsword","Stormcaller Spear","Moonstring Bow","Nightfang Daggers","Runekeeper Staff"]:
  var model=HeroVisual.new({"Weapon":weapon,"Chest":"Knight’s Harness","Shield":"None"},{"sex":"Male","class":"Warrior"});add_child(model);model.battle=true
  await shot(State.equipment_data[weapon].id);model.queue_free();await get_tree().process_frame
 var dragon=CompanionVisual.build("dragon");add_child(dragon)
 await shot("dragon_ground_front")
 camera.position=Vector3(-3.8,1.6,.8);camera.look_at(Vector3(0,.9,0))
 await shot("dragon_ground_side")
 dragon.motion(true);await shot("dragon_walk")
 dragon.player.play(dragon.resolve_clip("Flight"));await shot("dragon_flight")
 dragon.queue_free();await get_tree().process_frame
 camera.position=Vector3(-2.7,1.8,-3.6);camera.look_at(Vector3(0,1,0))
 State.new_adventure();State.create_hero("Ash","Barbarian",0,0,0,["Wizard","Healer"],"Male")
 var box=Dialogue.new();add_child(box)
 for who in ["Hero","King Aldren","Archivist Safiya","Vorr"]:
  box.database.preview=[[who,"The portrait now follows the actual speaker, including your chosen hero."]];box.show_id("preview")
  await shot("portrait_"+who.replace(" ","_"));box.advance()
 box.queue_free()
 camera.position=Vector3(-4,2.8,5);camera.look_at(Vector3(0,1,0));camera.fov=50
 var hero=HeroVisual.new({"Weapon":"Flamebrand","Chest":"Knight’s Harness","Shield":"None"},{"sex":"Male","class":"Warrior"});add_child(hero);hero.position=Vector3(-1.5,0,0);hero.battle=true
 var enemy=Art.actor("Goblin");add_child(enemy);enemy.position=Vector3(1.5,0,0)
 for label in ["Dragon Slash","Sacred Strike","Sundering Roar","Deathmark"]:
  hero.play_action(label);ThematicEffects.show(self,hero,enemy,label)
  await shot("effect_"+label.replace(" ","_"));await get_tree().create_timer(1.5).timeout
 await Sound.stop_all();get_tree().quit()

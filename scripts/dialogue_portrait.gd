class_name DialoguePortrait
extends SubViewport
const PEOPLE={"Mira":["Healer","Female"],"King Aldren":["Paladin","Male"],"Messenger Elian":["Ranger","Male"],"Warden Iona":["Druid","Female"],"Healer Sella":["Healer","Female"],"Ferryman Jory":["Ranger","Male"],"Archivist Safiya":["Wizard","Female"],"Forgekeeper Brann":["Warrior","Male"],"Captain Rowan":["Warrior","Male"],"Artisan Nessa":["Wizard","Female"],"Keeper Oren":["Druid","Male"]}
var world:Node3D
var model:Node3D
var camera:Camera3D
var identity=""
func _ready():
 size=Vector2i(256,256);own_world_3d=true;transparent_bg=false
 render_target_update_mode=SubViewport.UPDATE_DISABLED
 world=Node3D.new();add_child(world)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("26394b");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.8;world.add_child(env)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-25,0);world.add_child(light)
 camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.fov=27
func show_speaker(who:String):
 if identity==who:
  render_target_update_mode=SubViewport.UPDATE_ALWAYS
  return
 identity=who
 if model:world.remove_child(model);model.queue_free()
 var humanoid=true
 if who=="Hero":
  var appearance=State.hero.profile.duplicate(true);appearance["class"]=State.hero.primary
  model=HeroVisual.new(State.hero.equipment,appearance)
 elif PEOPLE.has(who):model=HeroVisual.new({"Chest":"Leather Vest","Weapon":"None","Shield":"None"},{"class":PEOPLE[who][0],"sex":PEOPLE[who][1]})
 else:
  humanoid=false
  var kinds={"The Hollow Warden":"Warden","Keeper of the Drowned Oath":"ReliquaryKeeper","Namarra":"GlassSovereign","Vorr":"IronrootColossus","Wolf":"Wolf"}
  model=Art.actor(kinds.get(who,"Wolf"))
 world.add_child(model);model.rotation.y=PI
 if humanoid:
  camera.position=Vector3(0,1.6,1.12);camera.look_at(Vector3(0,1.57,0))
 else:
  var bounds=GearVisual.bounds(model);var height=maxf(bounds.size.y,1)
  camera.position=Vector3(0,height*.74,height*1.25);camera.look_at(Vector3(0,height*.64,0))
 render_target_update_mode=SubViewport.UPDATE_ALWAYS

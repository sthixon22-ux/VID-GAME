extends Node3D
var hero:HeroVisual
var pet:CompanionActor
var caption:Label
func _ready():call_deferred("run")
func run():
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color("233044")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color.WHITE
 env.environment.ambient_light_energy=.48
 add_child(env)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-38,-30,0)
 light.light_energy=.8
 light.shadow_enabled=true
 add_child(light)
 var fill=DirectionalLight3D.new()
 fill.rotation_degrees=Vector3(-15,130,0)
 fill.light_energy=.2
 add_child(fill)
 Art.box(self,Vector3(0,-.055,0),Vector3(25,.1,25),Color("344357"))
 var camera=Camera3D.new()
 camera.fov=33
 add_child(camera)
 camera.position=Vector3(3.7,2.4,6.4)
 camera.look_at(Vector3(0,.95,0))
 var canvas=CanvasLayer.new()
 add_child(canvas)
 caption=Label.new()
 caption.position=Vector2(25,22)
 caption.add_theme_font_size_override("font_size",24)
 canvas.add_child(caption)
 hero=HeroVisual.new({"Chest":"Leather Vest","Weapon":"Iron Sword","Shield":"Oak Shield","Helmet":"Ranger Hood"},{"class":"Ranger","sex":"Female"})
 add_child(hero)
 hero.position.x=-1.0
 hero.rotation.y=PI
 DirAccess.make_dir_recursive_absolute("/tmp/verdant-companion-review")
 for id in State.companions:
  if pet:pet.free()
  pet=CompanionVisual.build(id)
  add_child(pet)
  pet.position.x=.9
  pet.rotation.y=PI
  caption.text=State.companions[id].name+" · Hero + companion\nNative rig / textured materials"
  await get_tree().create_timer(.25).timeout
  await shot(id)
  pet.play_action(State.companions[id].name+" · strike")
  await get_tree().create_timer(.3).timeout
  await shot(id+"_attack")
  pet.action_remaining=0
  pet.motion(true,true)
  await get_tree().create_timer(.25).timeout
  await shot(id+"_run")
 get_tree().quit()
func shot(id:String):
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("/tmp/verdant-companion-review/"+id+".png")
 print("Captured ",id)

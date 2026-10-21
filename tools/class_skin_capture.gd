extends Node3D
var actors:Array[Node3D]=[]
var caption:Label
func _ready():call_deferred("run")
func run():
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color("233044")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color.WHITE
 env.environment.ambient_light_energy=.5
 add_child(env)
 var key=DirectionalLight3D.new()
 key.rotation_degrees=Vector3(-35,-25,0)
 key.light_energy=.7
 add_child(key)
 var fill=DirectionalLight3D.new()
 fill.rotation_degrees=Vector3(-15,125,0)
 fill.light_energy=.25
 add_child(fill)
 Art.box(self,Vector3(0,-.055,0),Vector3(10,.1,10),Color("344357"))
 var camera=Camera3D.new()
 camera.fov=30
 add_child(camera)
 camera.position=Vector3(0,1.15,4.5)
 camera.look_at(Vector3(0,.95,0))
 var layer=CanvasLayer.new()
 add_child(layer)
 caption=Label.new()
 caption.position=Vector2(30,25)
 caption.add_theme_font_size_override("font_size",25)
 layer.add_child(caption)
 var output="/tmp/verdant-class-skins"
 DirAccess.make_dir_recursive_absolute(output)
 var classes=State.classes.keys()
 for primary in classes:
  for actor in actors:actor.free()
  actors.clear()
  for sex in ["Male","Female"]:
   var actor=HeroVisual.new({"Weapon":"None","Shield":"None","Chest":"None"},{"sex":sex,"class":primary})
   add_child(actor)
   actor.position.x=-.6 if sex=="Male" else .6
   actor.rotation.y=PI
   actors.append(actor)
  caption.text="%s — Male / Female\n%s  ·  %s\nClass clothing only · no equipped gear" % [primary,HeroSkinBook.profile(primary,"Male").title,HeroSkinBook.profile(primary,"Female").title]
  await get_tree().create_timer(.15).timeout
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png(output.path_join(primary.to_lower()+".png"))
  print("Captured ",primary)
 get_tree().quit()

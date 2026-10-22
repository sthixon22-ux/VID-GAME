class_name MarshArt
extends RefCounted
static func atmosphere(root:Node3D,interior:bool=false):
 for child in root.get_children():
  if child is WorldEnvironment:
   child.environment.fog_enabled=true
   child.environment.fog_light_color=Color("729b9e")
   child.environment.fog_density=.012 if interior else .008
   child.environment.ambient_light_color=Color("a9caca")
   child.environment.ambient_light_energy=.35 if interior else .5
   child.environment.tonemap_exposure=.85
   if child.environment.sky and child.environment.sky.sky_material is ProceduralSkyMaterial:
    var sky=child.environment.sky.sky_material
    sky.sky_top_color=Color("405c70")
    sky.sky_horizon_color=Color("809d9d")
    sky.ground_horizon_color=Color("687f7c")
  if child is DirectionalLight3D:
   child.light_color=Color("cadce0")
   child.light_energy=.7
static func npc(root:Node3D,pos:Vector3,label:String,class_:String,sex:String):
 var actor=load("res://scripts/hero_visual.gd").new({"Chest":"Leather Vest","Weapon":"None","Shield":"None"},{"class":class_,"sex":sex})
 root.add_child(actor)
 actor.position=pos
 actor.rotation.y=PI
 Art.sign_(root,pos+Vector3(0,2.5,0),label+" [E]")
static func lantern(root:Node3D,pos:Vector3,label:String=""):
 Art.box(root,pos+Vector3(0,.65,0),Vector3(.22,1.3,.22),Color("685a43"))
 var glass=Art.shape(root,pos+Vector3(0,1.5,0),Vector3(.3,.45,.3),Color("82e5d7"))
 glass.material_override.emission_enabled=true
 glass.material_override.emission=Color("44b4b7")
 var light=OmniLight3D.new()
 light.position=pos+Vector3(0,1.7,0)
 light.light_color=Color("82d9d8")
 light.light_energy=.7
 light.omni_range=4
 root.add_child(light)
 if label!="":Art.sign_(root,pos+Vector3(0,2.4,0),label)
static func settlement(root:Node3D):
 npc(root,Vector3(-3.5,0,0),"Messenger Elian","Ranger","Male")
 # Market awnings, stock tables, ferry landing and gathered civic square.
 for x in [-5.0,5.0]:
  for z in [-9.0,-7.0]:
   for dx in [-1.4,1.4]:Art.box(root,Vector3(x+dx,1.3,z),Vector3(.12,2.6,.12),Color("695945"))
  var roof=Art.box(root,Vector3(x,2.7,-8),Vector3(3.3,.12,3),Color("708d9d" if x<0 else "a89d76"))
  roof.rotation.z=.06 if x<0 else -.06
  Art.box(root,Vector3(x,.7,-8),Vector3(2.6,.15,.9),Color("7f7054"))
  for i in 3:
   var gear=GearVisual.item(["Iron Sword","Oak Staff","Twin Daggers"][i] if x<0 else ["Traveler's Clothing","Traveler's Pendant","potion"][i])
   root.add_child(gear)
   gear.position=Vector3(x-1+i,.95,-8)
   gear.scale=Vector3.ONE*.45
 for z in [-1.0,-15.0,-24.0,-36.0,-49.0,-59.0]:
  for x in [-3.4,3.4]:lantern(root,Vector3(x,0,z))
 Art.sign_(root,Vector3(0,3,4),"REEDCROSS\nRoyal relief camp · Inn north\nCauseway & waterworks beyond")
 for i in 8:
  Art.box(root,Vector3(12+i*.6,.15,-16),Vector3(.5,.25,4),Color("867150"))
 Art.sign_(root,Vector3(13,2.7,-16),"Ferry landing · high water")
 for i in 4:
  Art.box(root,Vector3(10+i*.8,.35,-2),Vector3(.7,.7,.7),Color("a28b60"))
static func ambience(root:Node):
 var player=AudioStreamPlayer.new()
 player.stream=load("res://assets/audio/mirefen_ambience.wav")
 root.add_child(player)
 player.volume_db=UserSettings.effects_db-10
 player.finished.connect(player.play)
 UserSettings.changed.connect(func():
  player.volume_db=UserSettings.effects_db-10
  player.stream_paused=UserSettings.muted)
 player.stream_paused=UserSettings.muted
 if DisplayServer.get_name()!="headless":player.play()

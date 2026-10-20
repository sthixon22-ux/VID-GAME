extends Node3D
var sim: Combat
var actors: Dictionary={}
var camera: Camera3D
var status: Label
var log_label: Label
var commands: VBoxContainer
var busy=false
var dialogue: Dialogue
var hero_bar: ProgressBar
var enemy_bar: ProgressBar
var breath=0.0
func _ready():
 if State.enemy_id=="goblin":
  Art.environment_(self)
  for i in range(12):
   var angle=i*TAU/12
   Art.tree(self,Vector3(sin(angle)*12,0,cos(angle)*12),1.2)
  Art.shape(self,Vector3(0,0,0),Vector3(13,0.05,10),Color("a29465"),"cylinder")
 else:
  sanctuary_arena()
 sim=Combat.new(State.hero,State.stats(),State.enemy_id)
 Art.sign_(self,Vector3(2,4.5 if State.enemy_id=="warden" else 3,0),str(sim.enemy.name).to_upper())
 dialogue=Dialogue.new()
 add_child(dialogue)
 Sound.theme_("battle")
 for entry in [["Hero",Vector3(-2,0,1)],["Wolf",Vector3(-3,0,-1)],["Goblin",Vector3(2,0,0)]]:
  var model=Art.actor(str(sim.enemy.model) if entry[0]=="Goblin" else entry[0],State.hero.equipment)
  add_child(model)
  model.position=entry[1]
  actors[entry[0]]=model
  model.look_at(Vector3(2,0,0) if entry[0]!="Goblin" else Vector3(-2,0,1))
 camera=Camera3D.new()
 add_child(camera)
 camera.position=Vector3(-4.8,3.4,6.4)
 camera.look_at(Vector3(0,1.3,0))
 camera.current=true
 var panel=UI.panel(self,Vector2(20,20),Vector2(700,205))
 status=UI.label(panel,"")
 hero_bar=ProgressBar.new()
 panel.add_child(hero_bar)
 hero_bar.custom_minimum_size=Vector2(0,14)
 hero_bar.show_percentage=false
 hero_bar.max_value=sim.stats.max_hp
 var green=StyleBoxFlat.new()
 green.bg_color=Color("71b789")
 green.set_corner_radius_all(4)
 hero_bar.add_theme_stylebox_override("fill",green)
 enemy_bar=ProgressBar.new()
 panel.add_child(enemy_bar)
 enemy_bar.custom_minimum_size=Vector2(0,14)
 enemy_bar.show_percentage=false
 enemy_bar.max_value=sim.enemy.hp
 var red=StyleBoxFlat.new()
 red.bg_color=Color("bd7771")
 red.set_corner_radius_all(4)
 enemy_bar.add_theme_stylebox_override("fill",red)
 log_label=UI.label(panel,"%s approaches!" % sim.enemy.name)
 commands=UI.panel(self,Vector2(20,390),Vector2(350,300))
 main_menu()
 refresh()
func _process(delta):
 breath+=delta
 if not busy:
  for model in actors.values(): Art.animate(model,breath,false)
func refresh():
 hero_bar.value=sim.h.hp
 enemy_bar.value=sim.enemy_hp
 status.text="Hero HP %s/%s · MP %s/%s
Wolf HP %s · %s HP %s · Round %s" % [sim.h.hp,sim.stats.max_hp,sim.h.mp,sim.stats.max_mp,sim.wolf_hp,sim.enemy.name,sim.enemy_hp,sim.turns]
func clear_menu():
 for c in commands.get_children():
  commands.remove_child(c)
  c.queue_free()
func main_menu():
 clear_menu()
 UI.button(commands,"Attack",func(): act("Attack"))
 UI.button(commands,"Weapon Skills",func(): submenu(["Sword Slash","Shield Bash"]))
 var spells=["Sacred Strike","Hunter's Mark","Thornbind","Regrowth"]
 var primary: String=State.hero.primary
 if State.can_mythic(primary): spells.append(State.classes[primary].mythic)
 UI.button(commands,"Spells",func(): submenu(spells))
 UI.button(commands,"Items · Potions %s" % sim.h.potions,func(): act("Items"))
 UI.button(commands,"Defend",func(): act("Defend"))
 UI.button(commands,"Companion",func(): companion_menu())
func submenu(actions: Array):
 clear_menu()
 for action in actions:
  var selected: String=action
  var b=UI.button(commands,"%s · %s MP" % [action,sim.cost(action)],func(): act(selected))
  b.disabled=not sim.legal(selected)
 UI.button(commands,"Back",main_menu)
func companion_menu():
 clear_menu()
 for behavior in ["Attack","Support","Defend"]:
  var selected: String=behavior
  UI.button(commands,behavior,func():
   sim.h.companion.behavior=selected
   main_menu())
 UI.button(commands,"Back",main_menu)
func act(action: String):
 if busy or not sim.legal(action): return
 busy=true
 clear_menu()
 var events=sim.round_(action)
 for event in events:
  log_label.text="%s: %s" % [sim.enemy.name if event.actor=="Goblin" else event.actor,event.text]
  if event.amount!=0: Sound.cue("heal" if event.amount<0 else "hit")
  var actor: Node3D=actors[event.actor]
  var target: Node3D=actors[event.target]
  if event.amount!=0: impact(target,event.amount<0,event.text)
  var origin=actor.position
  var tween=create_tween()
  tween.tween_property(actor,"position",origin+(target.position-origin).normalized()*0.5,0.16)
  tween.tween_property(actor,"position",origin,0.18)
  var number=Label3D.new()
  add_child(number)
  number.position=target.position+Vector3(0,2.2,0)
  number.text=str(event.amount) if event.amount>0 else ("+%s" % -event.amount if event.amount<0 else event.text)
  number.font_size=60
  number.modulate=Color.SALMON if event.amount>0 else Color.LIGHT_GREEN
  var float_tween=create_tween()
  float_tween.tween_property(number,"position:y",3.4,0.6)
  float_tween.tween_callback(number.queue_free)
  var focus=target.position+Vector3(0,1,0)
  var shot=focus+Vector3(-3.8 if event.target=="Goblin" else 3.8,2.2,5.0)
  var cam_tween=create_tween()
  cam_tween.set_parallel(true)
  cam_tween.tween_property(camera,"position",shot,0.23).set_trans(Tween.TRANS_SINE)
  cam_tween.tween_method(func(weight: float): camera.look_at(Vector3(0,1.3,0).lerp(focus,weight)),0.0,1.0,0.23)
  await get_tree().create_timer(0.65).timeout
 var reset_camera=create_tween()
 reset_camera.set_parallel(true)
 reset_camera.tween_property(camera,"position",Vector3(-4.8,3.4,6.4),0.3)
 reset_camera.tween_method(func(weight: float): camera.look_at(Vector3(0,1.3,0)),0.0,1.0,0.3)
 refresh()
 busy=false
 if sim.outcome!="": finish()
 else: main_menu()
func finish():
 State.hero=sim.h
 var previous=int(State.hero.potions)
 if sim.outcome=="Victory":
  State.reward(true,sim.species)
  State.cleared_until[State.encounter_id]=Time.get_ticks_msec()+45000
  if sim.species=="mossling":
   var guardian=State.encounter_id-100
   if not State.hero.journey.guards.has(guardian): State.hero.journey.guards.append(guardian)
  if sim.species=="warden":
   State.hero.journey.boss=true
   State.hero.equipment.Weapon="Sunsteel Sword"
   Sound.theme_("woodland")
  Sound.cue("victory")
  var fall=create_tween()
  fall.tween_property(actors.Goblin,"scale",Vector3.ONE*0.01,0.6)
 else:
  State.hero.journey.region="forest"
  State.remember_position(Vector3.ZERO)
 State.save_game()
 clear_menu()
 if sim.outcome=="Victory":
  log_label.text="Victory! +%s XP · +%s gold · %s\n%s" % [sim.enemy.xp,sim.enemy.gold,"Potion found!" if State.hero.potions>previous else "No item drop.","The guardian is free. Bring the living ember to Mira." if sim.species=="warden" else ("The seal is now unguarded. Cleanse it with E." if sim.species=="mossling" else "Normal goblin victories: %s/10" % State.hero.mastery)]
 else: log_label.text="Defeat. Retreat to Willowbrook and press R at camp to recover."
 if sim.species=="warden" and sim.outcome=="Victory":
  UI.button(commands,"Speak to the guardian",func(): dialogue.show_id("boss_win",return_to_adventure))
 else: UI.button(commands,"Continue adventure",return_to_adventure)
func return_to_adventure():
 get_tree().change_scene_to_file(State.travel_scene())

func impact(target: Node3D, healing: bool, action: String):
 var color_=Color("91e8ac") if healing else (Color("ffe09a") if action in ["Sacred Strike","Dawn Avatar"] else Color("ffd0a3"))
 for i in range(7):
  var spark=Art.shape(self,target.position+Vector3(0,1,0),Vector3.ONE*0.13,color_)
  var angle=i*TAU/7
  var destination=spark.position+Vector3(sin(angle)*0.9,0.5+cos(angle)*0.5,cos(angle)*0.5)
  var tween=create_tween()
  tween.set_parallel(true)
  tween.tween_property(spark,"position",destination,0.4)
  tween.tween_property(spark,"scale",Vector3.ONE*0.01,0.4)
  tween.chain().tween_callback(spark.queue_free)

func sanctuary_arena():
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color("142336")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color("a7c9c3")
 env.environment.ambient_light_energy=0.5
 add_child(env)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-55,-20,0)
 light.light_color=Color("bfd8d5")
 light.light_energy=0.75
 light.shadow_enabled=true
 add_child(light)
 Art.box(self,Vector3(0,-0.2,0),Vector3(24,0.4,22),Color.WHITE).material_override=Art.surface(Color("8a9b8d"),"stone",10)
 for i in range(10):
  var angle=i*TAU/10
  var pos=Vector3(sin(angle)*9,0,cos(angle)*9)
  Art.shape(self,pos+Vector3(0,1.5,0),Vector3(1,3,1),Color("86957e"),"cylinder").material_override=Art.surface(Color("99a78e"),"stone",2)
  var crystal=Art.shape(self,pos+Vector3(0,3.3,0),Vector3(0.4,0.7,0.4),Color("83dec8"),"cone")
  var lamp=OmniLight3D.new()
  crystal.add_child(lamp)
  lamp.light_color=Color("9cddd5")
  lamp.omni_range=6
  lamp.light_energy=0.8

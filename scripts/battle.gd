extends Node3D
var options: OptionsPanel
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
 options=OptionsPanel.new()
 add_child(options)
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
  if model.has_method("play_action"): model.battle=true
  model.look_at(Vector3(2,0,0) if entry[0]!="Goblin" else Vector3(-2,0,1))
 camera=Camera3D.new()
 add_child(camera)
 camera.position=Vector3(-4.8,3.4,6.4)
 camera.look_at(Vector3(0,1.3,0))
 camera.current=true
 UI.button(UI.panel(self,Vector2(1080,20),Vector2(180,65)),"Settings",func():
  if not busy: options.open())
 var panel=UI.panel(self,Vector2(20,20),Vector2(700,155))
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
func refresh(snapshot: Dictionary={}):
 var hp=int(snapshot.get("hp",sim.h.hp))
 var mp=int(snapshot.get("mp",sim.h.mp))
 var wolf_hp=int(snapshot.get("wolf_hp",sim.wolf_hp))
 var enemy_hp=int(snapshot.get("enemy_hp",sim.enemy_hp))
 hero_bar.value=hp
 enemy_bar.value=enemy_hp
 status.text="Hero HP %s/%s · MP %s/%s\nWolf HP %s · %s HP %s · Round %s" % [hp,sim.stats.max_hp,mp,sim.stats.max_mp,wolf_hp,sim.enemy.name,enemy_hp,sim.turns]
func clear_menu():
 for c in commands.get_children():
  commands.remove_child(c)
  c.queue_free()
func main_menu():
 commands.get_parent().get_parent().show()
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
 if busy or options.active or not sim.legal(action): return
 busy=true
 commands.get_parent().get_parent().hide()
 clear_menu()
 if actors.Hero.has_method("play_action"): actors.Hero.guarding=false
 var events=sim.round_(action)
 for event in events:
  log_label.text="%s: %s" % [sim.enemy.name if event.actor=="Goblin" else event.actor,event.text]
  if event.amount!=0: Sound.cue("heal" if event.amount<0 else "hit")
  var actor: Node3D=actors[event.actor]
  var target: Node3D=actors[event.target]
  var duration=0.25
  if not UserSettings.minimal_animations: duration=await BattleMotion.present(self,actor,target,event.text)
  refresh(event.state)
  if not UserSettings.minimal_animations and event.amount>0 and target.has_method("play_reaction"): target.play_reaction()
  var number=Label3D.new()
  add_child(number)
  number.position=target.position+Vector3(0,2.2,0)
  number.text=str(event.amount) if event.amount>0 else ("+%s" % -event.amount if event.amount<0 else event.text)
  number.font_size=60
  number.modulate=Color.SALMON if event.amount>0 else Color.LIGHT_GREEN
  var float_tween=UserSettings.tween(self)
  float_tween.tween_property(number,"position:y",3.4,0.6)
  float_tween.tween_callback(number.queue_free)
  if not UserSettings.reduced_camera_motion and not UserSettings.minimal_animations:
   var focus=target.position+Vector3(0,1,0)
   var shot=focus+Vector3(-3.8 if event.target=="Goblin" else 3.8,2.2,5.0)
   var cam_tween=UserSettings.tween(self)
   cam_tween.set_parallel(true)
   cam_tween.tween_property(camera,"position",shot,0.23).set_trans(Tween.TRANS_SINE)
   cam_tween.tween_method(func(weight: float): camera.look_at(Vector3(0,1.3,0).lerp(focus,weight)),0.0,1.0,0.23)
  await get_tree().create_timer(UserSettings.duration(duration*0.62)).timeout
 if not UserSettings.reduced_camera_motion and not UserSettings.minimal_animations:
  var reset_camera=UserSettings.tween(self)
  reset_camera.set_parallel(true)
  reset_camera.tween_property(camera,"position",Vector3(-4.8,3.4,6.4),0.3)
  reset_camera.tween_method(func(weight: float): camera.look_at(Vector3(0,1.3,0)),0.0,1.0,0.3)
 refresh()
 busy=false
 if sim.outcome!="": finish()
 else: main_menu()
func finish():
 commands.get_parent().get_parent().show()
 if actors.Hero.has_method("play_action"): actors.Hero.play_action("Victory" if sim.outcome=="Victory" else "Defeat")
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
  var fall=UserSettings.tween(self)
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
  var tween=UserSettings.tween(self)
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

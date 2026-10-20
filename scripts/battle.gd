extends Node3D
var sim: Combat
var actors: Dictionary={}
var camera: Camera3D
var status: Label
var log_label: Label
var commands: VBoxContainer
var busy=false
func _ready():
 Art.environment_(self)
 for i in range(12):
  var angle=i*TAU/12
  Art.tree(self,Vector3(sin(angle)*12,0,cos(angle)*12),1.2)
 Art.shape(self,Vector3(0,0,0),Vector3(13,0.05,10),Color("a29465"),"cylinder")
 Art.sign_(self,Vector3(2,3,0),"FOREST GOBLIN")
 sim=Combat.new(State.hero,State.stats())
 for entry in [["Hero",Vector3(-2,0,1)],["Wolf",Vector3(-3,0,-1)],["Goblin",Vector3(2,0,0)]]:
  var model=Art.actor(entry[0],State.hero.equipment)
  add_child(model)
  model.position=entry[1]
  actors[entry[0]]=model
  model.look_at(Vector3(2,0,0) if entry[0]!="Goblin" else Vector3(-2,0,1))
 camera=Camera3D.new()
 add_child(camera)
 camera.position=Vector3(5,4,8)
 camera.look_at(Vector3(0,0.9,0))
 camera.current=true
 var panel=UI.panel(self,Vector2(20,20),Vector2(700,160))
 status=UI.label(panel,"")
 log_label=UI.label(panel,"Forest Goblin approaches!")
 commands=UI.panel(self,Vector2(20,390),Vector2(350,300))
 main_menu()
 refresh()
func refresh():
 status.text="Hero HP %s/%s · MP %s/%s
Wolf HP %s · Goblin HP %s · Round %s" % [sim.h.hp,sim.stats.max_hp,sim.h.mp,sim.stats.max_mp,sim.wolf_hp,sim.enemy_hp,sim.turns]
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
  log_label.text="%s: %s" % [event.actor,event.text]
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
  var shot=focus+Vector3(3.8,2.2,5.0)
  var cam_tween=create_tween()
  cam_tween.set_parallel(true)
  cam_tween.tween_property(camera,"position",shot,0.23).set_trans(Tween.TRANS_SINE)
  cam_tween.tween_method(func(weight: float): camera.look_at(Vector3(0,0.9,0).lerp(focus,weight)),0.0,1.0,0.23)
  await get_tree().create_timer(0.65).timeout
 var reset_camera=create_tween()
 reset_camera.set_parallel(true)
 reset_camera.tween_property(camera,"position",Vector3(5,4,8),0.3)
 reset_camera.tween_method(func(weight: float): camera.look_at(Vector3(0,0.9,0)),0.0,1.0,0.3)
 refresh()
 busy=false
 if sim.outcome!="": finish()
 else: main_menu()
func finish():
 State.hero=sim.h
 var previous=int(State.hero.potions)
 if sim.outcome=="Victory":
  State.reward(true)
  State.cleared_until[State.encounter_id]=Time.get_ticks_msec()+45000
 State.save_game()
 clear_menu()
 if sim.outcome=="Victory":
  log_label.text="Victory! +35 XP · +18 gold · %s
Normal victories: %s/10. %s
%s" % ["Potion found!" if State.hero.potions>previous else "No item drop.",State.hero.mastery,"Auto-Battle unlocked!" if State.hero.mastery>=10 else "",State.notice]
 else: log_label.text="Defeat. No rewards. Return to camp and press R to recover."
 UI.button(commands,"Return to forest",func(): get_tree().change_scene_to_file("res://scenes/world.tscn"))

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

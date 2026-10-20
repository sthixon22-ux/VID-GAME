extends Node3D
var hero: Node3D
var wolf: Node3D
var camera: Camera3D
var goblins: Array[Node3D]=[]
var yaw=0.0
var pitch=-0.45
var hud: Label
var menu: VBoxContainer
var message=""
func _ready():
 Art.environment_(self)
 for i in range(32):
  var x=sin(i*7.3)*21
  var z=cos(i*4.7)*21
  if absf(x)<4 and absf(z)<8: continue
  Art.box(self,Vector3(x,1.5,z),Vector3(0.6,3,0.6),Color.SADDLE_BROWN)
  Art.box(self,Vector3(x,3.5,z),Vector3(2.8,2.5,2.8),Color(0.13,0.38,0.19))
 hero=Art.actor("Hero",State.hero.equipment)
 add_child(hero)
 wolf=Art.actor("Wolf")
 add_child(wolf)
 for pos in [Vector3(0,0,-6),Vector3(7,0,-3),Vector3(-7,0,-8)]:
  var gob=Art.actor("Goblin")
  add_child(gob)
  gob.position=pos
  goblins.append(gob)
 camera=Camera3D.new()
 add_child(camera)
 camera.current=true
 var panel=UI.panel(self,Vector2(16,16),Vector2(580,100))
 hud=UI.label(panel,"")
 UI.label(panel,"WASD move · Hold right mouse + move to orbit · E battle · Q auto")
 UI.label(panel,"I equipment / skills · F5 save · F9 load · R rest at camp")
 menu=UI.panel(self,Vector2(820,20),Vector2(440,680))
 menu.get_parent().get_parent().visible=false
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func _unhandled_input(event):
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  yaw-=event.relative.x*0.005
  pitch=clampf(pitch-event.relative.y*0.004,-1.1,-0.15)
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_E: encounter(false)
   KEY_Q: encounter(true)
   KEY_I:
    menu.get_parent().get_parent().visible=not menu.get_parent().get_parent().visible
    if menu.get_parent().get_parent().visible: refresh_menu()
   KEY_F5:
    State.save_game()
    message="Saved."
   KEY_F9:
    State.load_game()
    update_gear()
    message="Loaded."
   KEY_R:
    if hero.position.length()<3:
     State.hero.hp=State.stats().max_hp
     State.hero.mp=State.stats().max_mp
     State.save_game()
     message="Rested at camp."
    else: message="Return to the central clearing to rest."
func _process(delta):
 if not menu.get_parent().get_parent().visible:
  var input=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
  var direction=input.rotated(Vector3.UP,yaw).normalized()
  hero.position+=direction*5*delta
  hero.position.x=clampf(hero.position.x,-23,23)
  hero.position.z=clampf(hero.position.z,-23,23)
  if direction.length()>0: hero.rotation.y=atan2(-direction.x,-direction.z)
 wolf.visible=State.hero.companion.active
 wolf.position=wolf.position.lerp(hero.position+Vector3(1,0,1.4),minf(1,delta*4))
 camera.position=hero.position+Vector3(sin(yaw)*cos(pitch)*7,-sin(pitch)*7+1,cos(yaw)*cos(pitch)*7)
 camera.look_at(hero.position+Vector3.UP)
 var s=State.stats()
 hud.text="%s / %s · Lv %s · XP %s/%s
HP %s/%s · MP %s/%s · Gold %s · Goblins %s/10
%s" % [State.hero.primary," / ".join(State.hero.secondary),State.hero.level,State.hero.xp,int(State.hero.level)*70,State.hero.hp,s.max_hp,State.hero.mp,s.max_mp,State.hero.gold,State.hero.mastery,message]
func encounter(auto: bool):
 if menu.get_parent().get_parent().visible: return
 var nearby=false
 for gob in goblins:
  if hero.position.distance_to(gob.position)<3: nearby=true
 if not nearby:
  message="Approach a visible goblin (within 3 meters)."
  return
 if State.hero.hp<=0:
  message="Rest at camp first."
  return
 if auto:
  if State.hero.mastery<10:
   message="Auto-Battle requires 10 normal goblin victories."
   return
  var sim=Combat.new(State.hero,State.stats())
  sim.auto_resolve()
  State.hero=sim.h
  if sim.outcome=="Victory": State.reward(false)
  message="Auto: %s in %s rounds. HP %s, MP %s. %s" % [sim.outcome,sim.turns,State.hero.hp,State.hero.mp,"+35 XP, +18 gold; drop roll applied." if sim.outcome=="Victory" else "No rewards. Rest at camp."]
  State.save_game()
 else: get_tree().change_scene_to_file("res://scenes/battle.tscn")
func update_gear():
 var pos=hero.position
 hero.queue_free()
 hero=Art.actor("Hero",State.hero.equipment)
 add_child(hero)
 hero.position=pos
func refresh_menu():
 for child in menu.get_children():
  menu.remove_child(child)
  child.queue_free()
 UI.label(menu,"Hero management · Skill points: %s" % State.hero.points)
 for c in State.classes:
  var class_key: String=c
  UI.button(menu,"%s: %s invested · Invest 1" % [c,State.hero.investments[c]],func():
   if State.hero.points>0 and State.hero.investments[class_key]<3:
    State.hero.points-=1
    State.hero.investments[class_key]+=1
    State.save_game()
    refresh_menu())
  UI.label(menu," → ".join(State.classes[c].tree))
  UI.button(menu,"Make %s primary (mythic at 3 points)" % c,func():
   State.hero.primary=class_key
   State.hero.secondary=State.classes.keys().filter(func(k): return k!=class_key)
   State.save_game()
   refresh_menu())
 UI.label(menu,"Trees: ranks 1–2 training; rank 3 mythic unlock.")
 UI.label(menu,"Primary: %s · All starting skills available" % State.hero.primary)
 for slot in State.hero.equipment:
  var slot_key: String=slot
  UI.button(menu,"%s: %s · Change" % [slot,State.hero.equipment[slot]],func():
   var options={"Weapon":["Iron Sword","Sunsteel Sword"],"Shield":["Oak Shield","None"],"Chest":["Steel Cuirass","Leather Vest"]}.get(slot_key,["None","Leather Gear"])
   State.hero.equipment[slot_key]=options[1] if State.hero.equipment[slot_key]==options[0] else options[0]
   update_gear()
   State.save_game()
   refresh_menu())
 UI.button(menu,"Wolf: %s · Change behavior" % State.hero.companion.behavior,func():
  var choices=["Attack","Support","Defend"]
  State.hero.companion.behavior=choices[(choices.find(State.hero.companion.behavior)+1)%3]
  State.save_game()
  refresh_menu())
 UI.button(menu,"Close",func(): menu.get_parent().get_parent().hide())

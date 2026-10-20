extends Node3D
var hero: Node3D
var wolf: Node3D
var camera: Camera3D
var goblins: Array[Node3D]=[]
var forest: Forest
var objective: Label
var prompt: Label
var time_=0.0
var goblin_homes=[Vector3(0,0,-9),Vector3(7,0,-17),Vector3(19,0,-12)]
var yaw=0.0
var pitch=-0.45
var hud: Label
var menu: VBoxContainer
var message=""
func _ready():
 forest=Forest.new()
 forest.build(self)
 hero=Art.actor("Hero",State.hero.equipment)
 add_child(hero)
 hero.position=State.return_position
 wolf=Art.actor("Wolf")
 add_child(wolf)
 for pos in goblin_homes:
  var gob=Art.actor("Goblin")
  add_child(gob)
  gob.position=pos
  goblins.append(gob)
  Art.sign_(gob,Vector3(0,2.6,0),"Forest Goblin")
 camera=Camera3D.new()
 add_child(camera)
 camera.current=true
 var panel=UI.panel(self,Vector2(16,16),Vector2(600,180))
 hud=UI.label(panel,"")
 UI.label(panel,"WASD move · Shift sprint · Right mouse orbit · E interact")
 UI.label(panel,"Q auto · I equipment / skills · F5 save · F9 load · R rest")
 var journal=UI.panel(self,Vector2(900,20),Vector2(360,150))
 objective=UI.label(journal,"")
 var bottom=UI.panel(self,Vector2(350,640),Vector2(580,60))
 prompt=UI.label(bottom,"")
 menu=UI.panel(self,Vector2(820,20),Vector2(440,680))
 menu.get_parent().get_parent().visible=false
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func _unhandled_input(event):
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  yaw-=event.relative.x*0.005
  pitch=clampf(pitch-event.relative.y*0.004,-1.1,-0.15)
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_E: interact()
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
 time_+=delta
 var direction=Vector3.ZERO
 if not menu.get_parent().get_parent().visible:
  var input=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
  direction=input.rotated(Vector3.UP,yaw).normalized()
  var speed=7.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.3
  var next=hero.position+direction*speed*delta
  if forest.can_walk(Vector3(next.x,0,hero.position.z)): hero.position.x=next.x
  if forest.can_walk(Vector3(hero.position.x,0,next.z)): hero.position.z=next.z
  if direction.length()>0: hero.rotation.y=lerp_angle(hero.rotation.y,atan2(-direction.x,-direction.z),minf(1,delta*12))
 hero.position.y=0.32 if absf(hero.position.x-12)<2.5 and absf(hero.position.z+12)<1.5 else 0.0
 animate_actor(hero,direction.length()>0)
 wolf.visible=State.hero.companion.active
 var follow=hero.position+Vector3(1,0,1.4)
 var moving=wolf.position.distance_to(follow)>0.3
 wolf.position=wolf.position.lerp(follow,minf(1,delta*4))
 if moving: wolf.rotation.y=lerp_angle(wolf.rotation.y,atan2(wolf.position.x-follow.x,wolf.position.z-follow.z),minf(1,delta*6))
 animate_actor(wolf,moving)
 for i in range(goblins.size()):
  var gob=goblins[i]
  gob.visible=Time.get_ticks_msec()>int(State.cleared_until.get(i,0))
  if gob.visible:
   gob.position=goblin_homes[i]+Vector3(sin(time_*0.5+i)*0.7,0,cos(time_*0.5+i)*0.7)
   gob.rotation.y=-time_*0.5-i
   animate_actor(gob,true)
 for i in range(forest.herbs.size()): forest.herbs[i].visible=not State.hero.exploration.herbs.has(i)
 var desired=hero.position+Vector3(sin(yaw)*cos(pitch)*8,-sin(pitch)*8+1.5,cos(yaw)*cos(pitch)*8)
 camera.position=camera.position.lerp(desired,minf(1,delta*9)) if time_>0.1 else desired
 camera.look_at(hero.position+Vector3.UP*1.2)
 var s=State.stats()
 hud.text="%s · Lv %s · XP %s/%s
HP %s/%s · MP %s/%s · Gold %s · Mastery %s/10
%s" % [State.hero.primary,State.hero.level,State.hero.xp,int(State.hero.level)*70,State.hero.hp,s.max_hp,State.hero.mp,s.max_mp,State.hero.gold,State.hero.mastery,message]
 objective.text="WILLOWBROOK / SUNSTREAM
Moonleaf for Mira: %s/3 %s
Find the shrine: %s" % [State.hero.exploration.herbs.size(),"✓" if State.hero.exploration.quest_done else "", "Discovered" if State.hero.exploration.shrine else "Across the eastern bridge"]
 prompt.text=context_prompt()
func animate_actor(model: Node3D, moving: bool):
 var body=model.get_node_or_null("Body")
 if body:
  body.position.y=absf(sin(time_*10))*0.08 if moving else sin(time_*2)*0.015
  body.rotation.z=sin(time_*10)*0.04 if moving else 0.0
func context_prompt() -> String:
 if hero.position.distance_to(Vector3(-2.6,0,-0.8))<2.4: return "[E] Talk to Mira · [R] Rest at camp"
 for herb in forest.herbs:
  if herb.visible and hero.position.distance_to(herb.position)<2: return "[E] Gather Moonleaf"
 if hero.position.distance_to(Vector3(24,0,-12))<3: return "[E] Discover the Verdant Shrine"
 for gob in goblins:
  if gob.visible and hero.position.distance_to(gob.position)<3: return "[E] Challenge Forest Goblin · [Q] Auto-Battle"
 if hero.position.length()<3: return "[R] Rest and restore HP / MP · Follow the northern trail"
 return "Explore the woodland · Cross the eastern bridge to the shrine"
func interact():
 if menu.get_parent().get_parent().visible: return
 if hero.position.distance_to(Vector3(-2.6,0,-0.8))<2.4:
  if State.hero.exploration.herbs.size()>=3 and not State.hero.exploration.quest_done:
   State.hero.exploration.quest_done=true
   State.hero.gold+=60
   State.hero.potions+=3
   message="Mira: Thank you! +60 gold and 3 potions."
   State.save_game()
  else: message="Mira: Find three purple Moonleaf plants along the trail and beyond the bridge."
  return
 for i in range(forest.herbs.size()):
  var herb=forest.herbs[i]
  if herb.visible and hero.position.distance_to(herb.position)<2:
   State.hero.exploration.herbs.append(i)
   herb.hide()
   State.hero.potions+=1
   message="Gathered Moonleaf! +1 potion. Bring all three to Mira."
   State.save_game()
   return
 if hero.position.distance_to(Vector3(24,0,-12))<3:
  if not State.hero.exploration.shrine:
   State.hero.exploration.shrine=true
   State.hero.gold+=30
   State.save_game()
   message="Verdant Shrine discovered! +30 gold. The old stone hums softly."
  else: message="The Verdant Shrine watches over Sunstream."
  return
 encounter(false)
func encounter(auto: bool):
 if menu.get_parent().get_parent().visible: return
 var nearby=false
 for gob in goblins:
  if gob.visible and hero.position.distance_to(gob.position)<3:
   nearby=true
   State.encounter_id=goblins.find(gob)
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
  if sim.outcome=="Victory":
   State.reward(false)
   State.cleared_until[State.encounter_id]=Time.get_ticks_msec()+45000
  message="Auto: %s in %s rounds. HP %s, MP %s. %s" % [sim.outcome,sim.turns,State.hero.hp,State.hero.mp,"+35 XP, +18 gold; drop roll applied." if sim.outcome=="Victory" else "No rewards. Rest at camp."]
  State.save_game()
 else:
  State.return_position=hero.position
  get_tree().change_scene_to_file("res://scenes/battle.tscn")
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

extends Node3D
var dialogue: Dialogue
var completion: VBoxContainer
var hero: Node3D
var wolf: Node3D
var camera: ExplorationCamera
var options: OptionsPanel
var auto_panel: AutoBattlePanel
var board: VBoxContainer
var elapsed_fraction=0.0
var goblins: Array[Node3D]=[]
var field_guards: Array[Node3D]=[]
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
 auto_panel=AutoBattlePanel.new()
 add_child(auto_panel)
 options=OptionsPanel.new()
 add_child(options)
 forest=Forest.new()
 forest.build(self)
 State.hero.journey.region="forest"
 dialogue=Dialogue.new()
 add_child(dialogue)
 Sound.theme_("woodland")
 hero=Art.actor("Hero",State.hero.equipment)
 add_child(hero)
 hero.position=State.return_position
 wolf=CompanionVisual.build(State.hero.companion.current)
 add_child(wolf)
 if State.hero.profile.economy:
  goblin_homes=[Vector3(-2,0,-12),Vector3(5,0,-24),Vector3(23,0,-7)]
  for pos in forest.herb_positions:
   var guard=Art.actor("Goblin")
   add_child(guard)
   guard.position=pos+Vector3(0.5,0,0.8)
   Art.sign_(guard,Vector3(0,2.6,0),"Moonleaf guard · [E]")
   field_guards.append(guard)
 for pos in goblin_homes:
  var gob=Art.actor("Goblin")
  add_child(gob)
  gob.position=pos
  goblins.append(gob)
  Art.sign_(gob,Vector3(0,2.6,0),"Forest Goblin")
 camera=ExplorationCamera.new()
 add_child(camera)
 camera.current=true
 var panel=UI.panel(self,Vector2(16,16),Vector2(600,180))
 hud=UI.label(panel,"")
 UI.label(panel,"WASD move · Shift sprint · Right mouse orbit · E interact")
 UI.label(panel,"Q auto · I gear · K skill trees · F5 save · F9 load · R rest")
 var journal=UI.panel(self,Vector2(900,20),Vector2(360,200))
 objective=UI.label(journal,"")
 var bottom=UI.panel(self,Vector2(350,640),Vector2(580,60))
 prompt=UI.label(bottom,"")
 menu=UI.panel(self,Vector2(820,20),Vector2(440,680))
 menu.get_parent().get_parent().visible=false
 completion=UI.panel(self,Vector2(340,200),Vector2(600,340))
 UI.label(completion,"THE BELL BENEATH THE WOODS
Adventure complete

You restored the guardian and brought light to Willowbrook.

Character art: KayKit / Kay Lousberg (CC0).
Village art and textures: Quaternius (CC0).
Story, music, portraits and effects: original.
Thank you for playing this development milestone.")
 UI.button(completion,"Keep exploring",func(): completion.get_parent().get_parent().hide())
 UI.button(completion,"Save and return to title",func():
  State.save_game()
  get_tree().change_scene_to_file("res://scenes/title.tscn"))
 completion.get_parent().get_parent().hide()
 board=UI.panel(self,Vector2(360,170),Vector2(560,390))
 board.get_parent().get_parent().hide()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if State.hero.profile.economy and not State.hero.demo.first_choice and State.hero.journey.finished:
  message="Your first permanent companion awaits. Open the Companion page [C]."
func _unhandled_input(event):
 if board.get_parent().get_parent().visible:
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
   board.get_parent().get_parent().hide()
   get_viewport().set_input_as_handled()
  return
 if auto_panel.active or options.active or dialogue.active or completion.get_parent().get_parent().visible: return
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  yaw-=event.relative.x*0.005*UserSettings.camera_sensitivity
  pitch=clampf(pitch-event.relative.y*0.004*UserSettings.camera_sensitivity,-1.1,-0.15)
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_E: interact()
   KEY_Q: encounter(true)
   KEY_I: open_character("equipment")
   KEY_K: open_character("skills")
   KEY_C: open_character("companions")
   KEY_J: open_character("journal")
   KEY_ESCAPE:
    menu.get_parent().get_parent().visible=not menu.get_parent().get_parent().visible
    if menu.get_parent().get_parent().visible: refresh_menu()
   KEY_F5:
    message="Saved." if State.save_game() else State.save_notice
   KEY_F9:
    State.load_game()
    if State.save_blocked: message=State.save_notice
    else: get_tree().change_scene_to_file(State.travel_scene())
   KEY_R:
    if hero.position.length()<3:
     State.hero.hp=State.stats().max_hp
     State.hero.mp=State.stats().max_mp
     State.restore_companion()
     State.save_game()
     message="Rested at camp. Hero and companion restored."
    else: message="Return to the central clearing to rest."
func _process(delta):
 time_+=delta
 var direction=Vector3.ZERO
 if not auto_panel.active and not board.get_parent().get_parent().visible and not options.active and not menu.get_parent().get_parent().visible and not dialogue.active and not completion.get_parent().get_parent().visible:
  var input=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
  direction=input.rotated(Vector3.UP,yaw).normalized()
  var speed=(7.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.3)*State.travel_multiplier()
  if State.hero.profile.economy:
   elapsed_fraction+=delta
   if elapsed_fraction>=1:
    State.hero.demo.elapsed+=int(elapsed_fraction)
    elapsed_fraction=fmod(elapsed_fraction,1.0)
  hero.position=ExplorationMotion.move(hero.position,direction*speed*delta,forest.can_walk)
  if direction.length()>0: hero.rotation.y=lerp_angle(hero.rotation.y,atan2(-direction.x,-direction.z),minf(1,delta*12))
 hero.position.y=0.32 if absf(hero.position.x-12)<2.5 and absf(hero.position.z+12)<1.5 else 0.0
 State.remember_position(hero.position)
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
 for i in range(field_guards.size()):
  field_guards[i].visible=not State.hero.demo.field_guards.has(i)
  animate_actor(field_guards[i],false)
 camera.update_view(hero.position+Vector3.UP*1.2,Vector3(sin(yaw)*cos(pitch)*8,-sin(pitch)*8+0.3,cos(yaw)*cos(pitch)*8),delta)
 var s=State.stats()
 hud.text="%s · Lv %s · XP %s/%s
HP %s/%s · MP %s/%s · Gold %s · Mastery %s/10
%s" % [State.hero.primary,State.hero.level,State.hero.xp,int(State.hero.level)*70,State.hero.hp,s.max_hp,State.hero.mp,s.max_mp,State.hero.gold,State.hero.mastery,message]
 var goal="Talk to Mira in Willowbrook"
 if State.hero.journey.started: goal="Gather Moonleaf: %s/3" % State.hero.exploration.herbs.size()
 if State.hero.exploration.herbs.size()==3: goal="Bring the Moonleaf to Mira"
 if State.hero.exploration.quest_done: goal="Enter the shrine beyond Sunstream"
 if State.hero.journey.boss: goal="Return to Mira with the living ember"
 if State.hero.journey.finished: goal="Choose your permanent companion [C]" if State.hero.companion.owned.is_empty() else "Adventure complete · Optional village board challenge"
 if State.hero.profile.economy and (State.hero.equipment.Weapon=="None" or State.hero.equipment.Chest=="None"): goal="Buy & equip a starter kit: outfitter east of camp"
 objective.text="THE BELL BENEATH THE WOODS\n%s\nRoot seals: %s/2" % [goal,State.hero.journey.seals.size()]
 prompt.text=context_prompt()
func animate_actor(model: Node3D, moving: bool):
 Art.animate(model,time_,moving)
func context_prompt() -> String:
 if hero.position.distance_to(Vector3(3.5,0,1))<2.2: return "[E] Willowbrook outfitter · Buy your first equipment"
 if hero.position.distance_to(Vector3(0,0,5))<2.2: return "[E] Village board · Training & postgame challenge"
 if hero.position.distance_to(Vector3(-2.6,0,-0.8))<2.4: return "[E] Talk to Mira · [R] Rest at camp"
 for herb in forest.herbs:
  if herb.visible and hero.position.distance_to(herb.position)<2:
   if State.hero.profile.economy and not State.hero.demo.field_guards.has(forest.herbs.find(herb)): return "[E] Challenge the visible Moonleaf guard"
   return "[E] Gather Moonleaf"
 if hero.position.distance_to(Vector3(24,0,-12))<3: return "[E] Enter the Rootbound Sanctuary"
 for gob in goblins:
  if gob.visible and hero.position.distance_to(gob.position)<3: return "[E] Challenge Forest Goblin · [Q] Auto-Battle"
 if hero.position.length()<3: return "[R] Rest and restore HP / MP · Follow the northern trail"
 return "Explore the woodland · Cross the eastern bridge to the shrine"
func interact():
 if auto_panel.active or options.active or board.get_parent().get_parent().visible or menu.get_parent().get_parent().visible or dialogue.active: return
 if hero.position.distance_to(Vector3(3.5,0,1))<2.2:
  open_character("shop")
  return
 if hero.position.distance_to(Vector3(0,0,5))<2.2:
  show_board()
  return
 if hero.position.distance_to(Vector3(-2.6,0,-0.8))<2.4:
  if State.hero.journey.boss and not State.hero.journey.finished:
   dialogue.show_id("ending",func():
    State.hero.journey.finished=true
    State.hero.gold+=120
    State.save_game()
    if State.hero.profile.economy: open_character("companions")
    else: completion.get_parent().get_parent().show())
  elif State.hero.journey.finished:
   dialogue.show_id("epilogue")
  elif not State.hero.journey.started:
   State.hero.journey.started=true
   State.save_game()
   dialogue.show_id("intro")
  elif State.hero.exploration.herbs.size()>=3 and not State.hero.exploration.quest_done:
   State.hero.exploration.quest_done=true
   State.hero.gold+=60
   State.hero.potions+=3
   State.restore()
   State.save_game()
   Sound.cue("heal")
   dialogue.show_id("herbs")
  else: dialogue.show_id("ready" if State.hero.exploration.quest_done else "reminder")
  return
 for i in range(forest.herbs.size()):
  var herb=forest.herbs[i]
  if herb.visible and hero.position.distance_to(herb.position)<2:
   if State.hero.profile.economy and not State.hero.demo.field_guards.has(i):
    if not ready_for_trail(): return
    State.enemy_id="goblin"
    State.encounter_id=300+i
    State.remember_position(hero.position)
    get_tree().change_scene_to_file("res://scenes/battle.tscn")
    return
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
  if not State.hero.exploration.quest_done:
   dialogue.show_id("sealed")
  else:
   dialogue.show_id("shrine",func():
    State.hero.journey.region="dungeon"
    State.remember_position(Vector3.ZERO)
    State.save_game()
    get_tree().change_scene_to_file("res://scenes/dungeon.tscn"))
  return
 encounter(false)
func encounter(auto: bool):
 if not ready_for_trail(): return
 if auto_panel.active or options.active or board.get_parent().get_parent().visible or menu.get_parent().get_parent().visible or dialogue.active: return
 var nearby=false
 State.enemy_id="goblin"
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
  auto_panel.open("goblin")
 else:
  State.return_position=hero.position
  get_tree().change_scene_to_file("res://scenes/battle.tscn")
func update_gear():
 var pos=hero.position
 hero.queue_free()
 hero=Art.actor("Hero",State.hero.equipment)
 add_child(hero)
 hero.position=pos
func open_character(page: String):
 State.menu_page=page
 State.remember_position(hero.position)
 get_tree().change_scene_to_file("res://scenes/character.tscn")
func refresh_menu():
 for child in menu.get_children():
  menu.remove_child(child)
  child.queue_free()
 UI.label(menu,"ADVENTURE MENU")
 UI.button(menu,"Equipment & Appearance  [I]",func(): open_character("equipment"))
 UI.button(menu,"Class Skill Trees  [K]",func(): open_character("skills"))
 UI.button(menu,"%s: %s · Change behavior" % [State.companion_name(),State.hero.companion.behavior],func():
  var choices=["Attack","Support","Defend"]
  State.hero.companion.behavior=choices[(choices.find(State.hero.companion.behavior)+1)%3]
  State.save_game()
  refresh_menu())
 UI.button(menu,"Companion bond  [C]",func(): open_character("companions"))
 UI.button(menu,"Journal & inventory  [J]",func(): open_character("journal"))
 UI.button(menu,"Settings",options.open)
 UI.button(menu,"Save and return to title",func():
  State.save_game()
  get_tree().change_scene_to_file("res://scenes/title.tscn"))
 UI.button(menu,"Close",func(): menu.get_parent().get_parent().hide())

func ready_for_trail() -> bool:
 if not State.hero.profile.economy: return true
 if not State.hero.journey.started:
  message="Speak to Mira beside the camp before setting out."
  return false
 if State.hero.equipment.Weapon=="None" or State.hero.equipment.Chest=="None" or State.hero.equipment.Shield=="None":
  message="Visit the outfitter near camp. Buy AND equip a sword, shield and chest piece first."
  return false
 if State.hero.hp<=0:
  message="Return to camp and press R to recover."
  return false
 return true
func show_board():
 for child in board.get_children():
  board.remove_child(child)
  child.queue_free()
 board.get_parent().get_parent().show()
 UI.label(board,"WILLOWBROOK FIELD BOARD").add_theme_font_size_override("font_size",24)
 UI.label(board,"First steps: buy your kit, spend skill points [K], speak to Mira.
Defend halves damage. Block with a shield to prime class chemistry.
Gather Moonleaf, return to Mira, then enter the sanctuary.
After the guardian: return to Mira and choose a companion [C].")
 UI.button(board,"Open journal & field guide",func(): open_character("journal"))
 if State.hero.journey.finished and not State.hero.companion.owned.is_empty():
  UI.label(board,"POSTGAME: challenge the Warden echo with your new companion.
Victory unlocks your second and final permanent companion choice.")
  UI.button(board,"Challenge the Warden echo",func():
   State.enemy_id="warden"
   State.encounter_id=1000
   State.remember_position(hero.position)
   State.save_game()
   get_tree().change_scene_to_file("res://scenes/battle.tscn")).disabled=State.hero.hp<=0 or State.hero.demo.echo
 UI.button(board,"Close",func(): board.get_parent().get_parent().hide())

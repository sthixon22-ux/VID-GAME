extends Node3D
var dialogue: Dialogue
var completion: VBoxContainer
var hero: Node3D
var wolf: Node3D
var camera: ExplorationCamera
var options: OptionsPanel
var hud_layer: ExplorationHUD
var contact_grace=1.5
var encounter_busy=false
var current_region=""
var pending_species="goblin"
var pending_id=0
var auto_panel: AutoBattlePanel
var board: VBoxContainer
var elapsed_fraction=0.0
var goblins: Array[Node3D]=[]
var field_guards: Array[Node3D]=[]
var forest: Forest
var objective: Label
var prompt: Label
var time_=0.0
var goblin_homes=[Vector3(-2,0,-21),Vector3(5,0,-34),Vector3(-3,0,-48),Vector3(28,0,-53),Vector3(48,0,-55),Vector3(59,0,-60)]
var species_list=["goblin","goblin","goblin","bristleback","bristleback","bristleback"]
var yaw=0.0
var pitch=-0.45
var hud: Label
var menu: VBoxContainer
var message=""
func _ready():
 State.shop_id="willowbrook"
 auto_panel=AutoBattlePanel.new()
 add_child(auto_panel)
 auto_panel.fight_requested.connect(func(): start_normal_battle(pending_species,pending_id))
 auto_panel.closed.connect(func():
  contact_grace=3.0
  if State.hero.hp<=0 and is_instance_valid(hero): hero.position=Vector3.ZERO)
 options=OptionsPanel.new()
 add_child(options)
 forest=Forest.new()
 forest.build(self)
 Art.sign_(self,Vector3(0,2.6,13),"Road to Reedcross [E]\nAfter the guardian's restoration")
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
  for pos in forest.herb_positions:
   var guard=Art.actor("Goblin")
   add_child(guard)
   guard.position=pos+Vector3(0.5,0,0.8)
   Art.sign_(guard,Vector3(0,2.6,0),"Moonleaf guard")
   field_guards.append(guard)
 for index in range(goblin_homes.size()):
  var gob=Art.actor("Goblin" if species_list[index]=="goblin" else "Bristleback")
  add_child(gob)
  gob.position=goblin_homes[index]
  goblins.append(gob)
  Art.sign_(gob,Vector3(0,2.6,0),"Forest Goblin" if species_list[index]=="goblin" else "Meadow Bristleback")
 camera=ExplorationCamera.new()
 add_child(camera)
 camera.current=true
 hud_layer=ExplorationHUD.new()
 add_child(hud_layer)
 hud=hud_layer.status
 objective=hud_layer.objective
 prompt=hud_layer.prompt
 hud_layer.map.markers=[{"position":Forest.SHRINE,"color":Color("8dc6ce")}]
 menu=UI.panel(self,Vector2(430,140),Vector2(420,460))
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
 if menu.get_parent().get_parent().visible and not (event is InputEventKey and event.keycode==KEY_ESCAPE): return
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  yaw-=event.relative.x*0.005*UserSettings.camera_sensitivity
  pitch=clampf(pitch-event.relative.y*0.004*UserSettings.camera_sensitivity,-1.1,-0.15)
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_E: interact()
   KEY_Q: encounter(true)
   KEY_TAB: open_character("inventory")
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
 var contact_from=hero.position
 time_+=delta
 contact_grace=maxf(0,contact_grace-delta)
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
 hero.position.y=0.28 if absf(hero.position.x-18)<2.5 and absf(hero.position.z+54)<1.6 else 0.0
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
   var target=goblin_homes[i]+Vector3(sin(time_*0.5+i)*0.9,0,cos(time_*0.5+i)*0.9)
   if hero.position.distance_to(gob.position)<5 and hero.position.distance_to(goblin_homes[i])<8 and State.starter_ready(): target=hero.position
   var step=(target-gob.position).limit_length(delta*1.9)
   gob.position=ExplorationMotion.move(gob.position,step,forest.can_walk)
   gob.rotation.y=-time_*0.5-i
   animate_actor(gob,true)
 for i in range(forest.herbs.size()): forest.herbs[i].visible=not State.hero.exploration.herbs.has(i)
 for i in range(field_guards.size()):
  field_guards[i].visible=not State.hero.demo.field_guards.has(i)
  animate_actor(field_guards[i],false)
 camera.update_view(hero.position+Vector3.UP*1.2,Vector3(sin(yaw)*cos(pitch)*8,-sin(pitch)*8+0.3,cos(yaw)*cos(pitch)*8),delta)
 var goal="Talk to Mira in Willowbrook"
 if State.hero.journey.started: goal="Gather Moonleaf: %s/3" % State.hero.exploration.herbs.size()
 if State.hero.exploration.herbs.size()==3: goal="Bring the Moonleaf to Mira"
 if State.hero.exploration.quest_done: goal="Enter the shrine beyond Sunstream"
 if State.hero.journey.boss: goal="Return to Mira with the living ember"
 if State.hero.journey.finished: goal="Choose your permanent companion [C]" if State.hero.companion.owned.is_empty() else "Travel south to Reedcross [E] · Village board echo available"
 if State.hero.profile.economy and not State.starter_ready(): goal="Buy a weapon: enter the western weapon shop"
 var region=Forest.region(hero.position)
 if region!=current_region:
  current_region=region
  message=region
 hud_layer.map.markers=[{"position":Forest.SHRINE,"color":Color("8dc6ce")}]
 for herb in forest.herbs:
  if herb.visible: hud_layer.map.markers.append({"position":herb.position,"color":Color("c598d3")})
 for door in TownServices.DOORS.forest:hud_layer.map.markers.append({"position":door[0],"color":Color("dbbe7d")})
 for npc in Forest.QUEST_NPCS: hud_layer.map.markers.append({"position":npc,"color":Color("dbbe7d")})
 for gob in goblins:
  if gob.visible: hud_layer.map.markers.append({"position":gob.position,"color":Color("ca7770")})
 if State.hero.side_quests.started.has("skyglass") and not State.hero.side_quests.claimed.has("skyglass"):
  for index in range(Forest.CRYSTALS.size()):
   if not State.hero.side_quests.crystals.has(index): hud_layer.map.markers.append({"position":Forest.CRYSTALS[index],"color":Color("8ac2e3")})
 hud_layer.update_view(hero.position,goal,context_prompt(),message+"  "+State.notice,delta)
 for i in range(forest.crystals.size()): forest.crystals[i].visible=not State.hero.side_quests.crystals.has(i)
 if not modal_active() and contact_grace<=0 and not encounter_busy: check_contact(contact_from)
func modal_active()->bool:
 return auto_panel.active or options.active or dialogue.active or menu.get_parent().get_parent().visible or board.get_parent().get_parent().visible or completion.get_parent().get_parent().visible
func check_contact(from_position:Vector3=Vector3.INF):
 if from_position==Vector3.INF: from_position=hero.position
 if State.hero.hp<=0 or not State.starter_ready(): return
 for i in range(goblins.size()):
  if goblins[i].visible and goblins[i].position.distance_to(Geometry3D.get_closest_point_to_segment(goblins[i].position,from_position,hero.position))<1.25:
   request_encounter(species_list[i],i,true)
   return
 for i in range(field_guards.size()):
  if field_guards[i].visible and field_guards[i].position.distance_to(Geometry3D.get_closest_point_to_segment(field_guards[i].position,from_position,hero.position))<1.25:
   request_encounter("goblin",300+i,true)
   return
func request_encounter(species:String,id:int,can_auto:bool):
 if modal_active() or encounter_busy or not ready_for_trail(): return
 pending_species=species
 pending_id=id
 State.enemy_id=species
 State.encounter_id=id
 State.remember_position(hero.position)
 if can_auto and State.species_wins(species)>=10: auto_panel.open(species,true)
 else: start_normal_battle(species,id)
func start_normal_battle(species:String,id:int):
 if encounter_busy: return
 encounter_busy=true
 State.enemy_id=species
 State.encounter_id=id
 State.remember_position(hero.position)
 get_tree().change_scene_to_file.call_deferred("res://scenes/battle.tscn")
func animate_actor(model: Node3D, moving: bool):
 Art.animate(model,time_,moving)
func context_prompt() -> String:
 var door=TownServices.nearby("forest",hero.position)
 if not door.is_empty():return "[E] Enter "+door[2]
 if State.hero.journey.finished and not State.hero.companion.owned.is_empty() and hero.position.distance_to(Vector3(0,0,13))<3: return "[E] Travel to Reedcross and Mirefen Marsh"
 if hero.position.distance_to(Vector3(3.5,0,1))<2.2:return "Weapons west · Armor east · Supplies and inn north"
 if hero.position.distance_to(Vector3(0,0,5))<2.2: return "[E] Village board · Training & postgame challenge"
 if hero.position.distance_to(Vector3(-2.6,0,-0.8))<2.4: return "[E] Talk to Mira · [R] Rest at camp"
 for i in range(Forest.QUEST_NPCS.size()):
  if hero.position.distance_to(Forest.QUEST_NPCS[i])<2: return "[E] "+QuestBook.data[QuestBook.data.keys()[i]].giver+" · Town errand"
 for crystal in forest.crystals:
  if crystal.visible and hero.position.distance_to(crystal.position)<2: return "[E] Gather skyglass"
 for herb in forest.herbs:
  if herb.visible and hero.position.distance_to(herb.position)<2:
   if State.hero.profile.economy and not State.hero.demo.field_guards.has(forest.herbs.find(herb)): return "Touch the Moonleaf guard to battle"
   return "[E] Gather Moonleaf"
 if hero.position.distance_to(Forest.SHRINE)<3: return "[E] Enter the Rootbound Sanctuary"
 for gob in goblins:
  if gob.visible and hero.position.distance_to(gob.position)<3: return "Contact starts battle · mastered species offer Auto-Battle"
 if hero.position.length()<3: return "[R] Rest and restore HP / MP · Follow the northern trail"
 return ""
func interact():
 if not modal_active():
  var door=TownServices.nearby("forest",hero.position)
  if not door.is_empty():
   TownServices.enter(get_tree(),"forest",door)
   return
 if State.hero.journey.finished and not State.hero.companion.owned.is_empty() and hero.position.distance_to(Vector3(0,0,13))<3:
  State.hero.journey.region="mirefen"
  State.remember_position(Vector3(0,0,4))
  State.save_game()
  get_tree().change_scene_to_file("res://scenes/mirefen.tscn")
  return
 if auto_panel.active or options.active or board.get_parent().get_parent().visible or menu.get_parent().get_parent().visible or dialogue.active: return
 if hero.position.distance_to(Vector3(3.5,0,1))<2.2:
  message="Enter the western house for weapons or the eastern house for armor."
  return
 if hero.position.distance_to(Vector3(0,0,5))<2.2:
  show_board()
  return
 if hero.position.distance_to(Vector3(-2.6,0,-0.8))<2.4:
  if State.hero.journey.boss and not State.hero.journey.finished:
   dialogue.show_id("ending",func():
    State.hero.journey.finished=true
    State.award_gold(120,"Mira’s ending reward")
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
   State.award_gold(60,"Moonleaf quest")
   State.hero.potions+=3
   State.restore()
   State.save_game()
   Sound.cue("heal")
   dialogue.show_id("herbs")
  else: dialogue.show_id("ready" if State.hero.exploration.quest_done else "reminder")
  return
 for i in range(Forest.QUEST_NPCS.size()):
  if hero.position.distance_to(Forest.QUEST_NPCS[i])<2:
   show_side_quest(QuestBook.data.keys()[i])
   return
 for i in range(forest.crystals.size()):
  if forest.crystals[i].visible and hero.position.distance_to(forest.crystals[i].position)<2:
   State.hero.side_quests.crystals.append(i)
   forest.crystals[i].hide()
   message="Skyglass gathered · %s/3. Return to Artisan Nessa in Willowbrook." % State.hero.side_quests.crystals.size()
   State.save_game()
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
 if hero.position.distance_to(Forest.SHRINE)<3:
  if not State.hero.exploration.shrine:
   State.hero.exploration.shrine=true
   State.award_gold(30,"Shrine discovery")
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
 if modal_active() or not ready_for_trail(): return
 for index in range(goblins.size()):
  if goblins[index].visible and hero.position.distance_to(goblins[index].position)<3:
   var species:String=species_list[index]
   if auto and State.species_wins(species)<10:
    message="Auto-Battle requires 10 normal victories for this species."
    return
   request_encounter(species,index,true)
   return
 message="Approach a visible enemy. Contact starts battle."
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
 UI.button(menu,"Inventory & healing  [Tab]",func(): open_character("inventory"))
 UI.button(menu,"Equipment & Appearance  [I]",func(): open_character("equipment"))
 UI.button(menu,"Class Skill Trees  [K]",func(): open_character("skills"))
 UI.button(menu,"%s: %s · Change behavior" % [State.companion_name(),State.hero.companion.behavior],func():
  var choices=["Attack","Support","Defend"]
  State.hero.companion.behavior=choices[(choices.find(State.hero.companion.behavior)+1)%3]
  State.save_game()
  refresh_menu())
 UI.button(menu,"Companion bond  [C]",func(): open_character("companions"))
 UI.button(menu,"Quest journal  [J]",func(): open_character("journal"))
 UI.button(menu,"Settings",options.open)
 UI.button(menu,"Save and return to title",func():
  State.save_game()
  get_tree().change_scene_to_file("res://scenes/title.tscn"))
 UI.button(menu,"Close",func(): menu.get_parent().get_parent().hide())

func ready_for_trail() -> bool:
 if not State.hero.profile.economy: return true
 if not State.starter_ready():
  message="Enter the western weapon shop to buy your first weapon. Armor and speaking to Mira are optional."
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
 UI.label(board,"Buy a weapon to fight. Armor is optional.
For the story: speak to Mira. Spend skill points [K] whenever you wish.
Defend halves damage. Paladin + Ranger + Druid: shield blocks prime class chemistry.
Gather Moonleaf, return to Mira, then enter the sanctuary.
Town errands: Rowan southwest, Nessa southeast, Oren west.
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

func show_side_quest(id:String):
 var entry:Dictionary=QuestBook.data[id]
 var text=entry.description+"\nReward: %s gold + %s XP." % [entry.gold,entry.xp]
 if State.hero.side_quests.claimed.has(id): text="Thank you. Your help has made Willowbrook safer."
 elif QuestBook.complete(State.hero,id):
  State.claim_side_quest(id)
  text="You did it! "+entry.name+" complete.\n"+State.notice+" · +%s XP" % entry.xp
 elif not State.hero.side_quests.started.has(id):
  State.accept_side_quest(id)
  text+="\nQuest added to your journal."
 else: text+="\nProgress: %s / %s" % [QuestBook.progress(State.hero,id),entry.goal]
 dialogue.database["side_quest"]=[[entry.giver,text]]
 dialogue.show_id("side_quest")

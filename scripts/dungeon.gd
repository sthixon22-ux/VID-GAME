extends Node3D
var hero: Node3D
var wolf: Node3D
var camera: ExplorationCamera
var auto_panel:AutoBattlePanel
var options: OptionsPanel
var dialogue: Dialogue
var hud_layer:ExplorationHUD
var puzzle_panel:VBoxContainer
var puzzle_index=0
var contact_grace=1.5
var encounter_busy=false
var gate:Node3D
var hud: Label
var objective: Label
var prompt: Label
var seals: Array[Node3D]=[]
var enemies: Array[Node3D]=[]
var floor_cells: Dictionary={}
var yaw=0.0
var pitch=-0.6
var clock=0.0
var elapsed_fraction=0.0
var boss: Node3D
var chest: Node3D
var pause_menu: VBoxContainer
var enemy_homes=[Vector3(-8,0,-10),Vector3(8,0,-10)]
func _ready():
 auto_panel=AutoBattlePanel.new()
 add_child(auto_panel)
 auto_panel.fight_requested.connect(func(): start_battle(State.enemy_id,State.encounter_id,true))
 auto_panel.closed.connect(func():
  contact_grace=3.0
  if State.hero.hp<=0: get_tree().change_scene_to_file.call_deferred("res://scenes/world.tscn"))
 options=OptionsPanel.new()
 add_child(options)
 build_dungeon()
 hero=Art.actor("Hero",State.hero.equipment)
 add_child(hero)
 hero.position=State.return_position
 if not can_walk(hero.position): hero.position=Vector3.ZERO
 wolf=CompanionVisual.build(State.hero.companion.current)
 add_child(wolf)
 wolf.position=hero.position+Vector3(1,0,1)
 camera=ExplorationCamera.new()
 add_child(camera)
 camera.current=true
 dialogue=Dialogue.new()
 add_child(dialogue)
 hud_layer=ExplorationHUD.new()
 add_child(hud_layer)
 hud_layer.map.dungeon=true
 hud_layer.map.floor_cells=floor_cells
 hud_layer.map.markers=[{"position":Vector3(-8,0,-13),"color":Color("d9ba79")},{"position":Vector3(8,0,-13),"color":Color("d9ba79")},{"position":Vector3(0,0,-29),"color":Color("c9796b")}]
 hud=hud_layer.status
 objective=hud_layer.objective
 prompt=hud_layer.prompt
 puzzle_panel=UI.panel(self,Vector2(350,140),Vector2(580,440))
 puzzle_panel.get_parent().get_parent().hide()
 pause_menu=UI.panel(self,Vector2(430,150),Vector2(420,420))
 pause_menu.get_parent().get_parent().hide()
 UI.button(pause_menu,"Resume",func(): pause_menu.get_parent().get_parent().hide())
 UI.button(pause_menu,"Inventory & healing",func(): open_character("inventory"))
 UI.button(pause_menu,"Quest journal",func(): open_character("journal"))
 UI.button(pause_menu,"Equipment & Appearance",func(): open_character("equipment"))
 UI.button(pause_menu,"Class Skill Trees",func(): open_character("skills"))
 UI.button(pause_menu,"Save",func(): State.save_game())
 UI.button(pause_menu,"Settings",options.open)
 UI.button(pause_menu,"Save and return to title",func():
  State.save_game()
  get_tree().change_scene_to_file("res://scenes/title.tscn"))
 Sound.theme_("sanctuary")
 if not State.hero.journey.entered:
  State.hero.journey.entered=true
  State.save_game()
  dialogue.show_id("dungeon")
func build_dungeon():
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color("142336")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color("90b7b6")
 env.environment.ambient_light_energy=0.6
 add_child(env)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-60,-25,0)
 light.light_color=Color("a7c3d4")
 light.light_energy=0.8
 light.shadow_enabled=true
 add_child(light)
 for x in range(-6,7):
  for z in range(-16,3):
   var center=Vector3(x*2,0,z*2)
   if (absf(center.x)<=2 and center.z>=-26) or (absf(center.x)<=10 and absf(center.z+10)<=2) or (absf(center.x)>=6 and absf(center.x)<=10 and center.z>=-14 and center.z<=-6) or (absf(center.x)<=6 and center.z>=-32 and center.z<=-24):
    floor_cells[Vector2i(x,z)]=true
 for cell in floor_cells:
  var point=Vector3(cell.x*2,0,cell.y*2)
  var tile=Art.box(self,point+Vector3(0,-0.14,0),Vector3(2,0.28,2),Color("697e77"))
  tile.material_override=Art.surface(Color("89998c"),"stone",1)
  for edge in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   if floor_cells.has(cell+edge): continue
   var wall_height=1.4 if edge==Vector2i.DOWN else 2.8
   var wall=Art.box(self,point+Vector3(edge.x,wall_height/2,edge.y),Vector3(0.28 if edge.x else 2.1,wall_height,0.28 if edge.y else 2.1),Color("61746d"))
   CameraObstacles.box(self,wall.position,Vector3(0.28 if edge.x else 2.1,wall_height,0.28 if edge.y else 2.1))
   wall.material_override=Art.surface(Color("8c9e8b"),"stone",1.2)
 for x in [-8,8]:
  var seal=Node3D.new()
  add_child(seal)
  seal.position=Vector3(x,0,-13)
  Art.shape(seal,Vector3(0,0.3,0),Vector3(1.8,0.6,1.8),Color("8c9a83"),"cylinder")
  Art.shape(seal,Vector3(0,1.2,0),Vector3(0.8,1.6,0.8),Color("95cfc1"),"cone")
  Art.sign_(seal,Vector3(0,2.5,0),"Root Seal · [E]")
  seals.append(seal)
 for i in range(2):
  var enemy=Art.actor("Mossling")
  add_child(enemy)
  enemy.position=enemy_homes[i]
  Art.sign_(enemy,Vector3(0,1.8,0),"Briar Mossling · [E]")
  enemies.append(enemy)
 chest=Node3D.new()
 add_child(chest)
 chest.position=Vector3(2,0,-19)
 Art.box(chest,Vector3(0,0.4,0),Vector3(1,0.8,0.7),Color("916846")).material_override=Art.surface(Color("ad8555"),"wood")
 Art.box(chest,Vector3(0,0.4,-0.38),Vector3(0.15,0.4,0.05),Color("e5c57d"))
 Art.sign_(chest,Vector3(0,1.5,0),"Pilgrim's cache · [E]")
 boss=Art.actor("Warden")
 add_child(boss)
 boss.position=Vector3(0,0,-29)
 Art.sign_(boss,Vector3(0,4.5,0),"THE HOLLOW WARDEN")
 gate=Art.box(self,Vector3(0,1.3,-23),Vector3(3.7,2.6,0.35),Color("506966"))
 gate.material_override=Art.surface(Color("8ea693"),"metal",2)
 Art.sign_(gate,Vector3(0,1.9,0),"Two seals bind this door")
 Art.sign_(self,Vector3(0,2,2),"WILLOWBROOK ↑\n[E] Leave sanctuary")
 for i in range(8):
  var pos=Vector3(-2 if i%2==0 else 2,1.7,-i*4)
  var crystal=Art.shape(self,pos,Vector3(0.3,0.7,0.3),Color("80d8d3"),"cone")
  var lamp=OmniLight3D.new()
  crystal.add_child(lamp)
  lamp.light_color=Color("7ad4d0")
  lamp.light_energy=1.2
  lamp.omni_range=5
func can_walk(pos: Vector3) -> bool:
 if pos.z< -22 and State.hero.journey.seals.size()<2: return false
 return floor_cells.has(Vector2i(floori((pos.x+1)/2),floori((pos.z+1)/2)))
func _unhandled_input(event):
 if auto_panel.active or options.active or dialogue.active: return
 if puzzle_panel.get_parent().get_parent().visible:
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: puzzle_panel.get_parent().get_parent().hide()
  return
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  yaw-=event.relative.x*0.005*UserSettings.camera_sensitivity
  pitch=clampf(pitch-event.relative.y*0.004*UserSettings.camera_sensitivity,-1.05,-0.3)
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_E: interact()
   KEY_TAB: open_character("inventory")
   KEY_I: open_character("equipment")
   KEY_K: open_character("skills")
   KEY_C: open_character("companions")
   KEY_J: open_character("journal")
   KEY_ESCAPE: pause_menu.get_parent().get_parent().visible=not pause_menu.get_parent().get_parent().visible
   KEY_F5: State.save_game()
func _process(delta):
 clock+=delta
 contact_grace=maxf(0,contact_grace-delta)
 var direction=Vector3.ZERO
 if not auto_panel.active and not options.active and not dialogue.active and not pause_menu.get_parent().get_parent().visible and not puzzle_panel.get_parent().get_parent().visible and not encounter_busy:
  if State.hero.profile.economy:
   elapsed_fraction+=delta
   if elapsed_fraction>=1:
    State.hero.demo.elapsed+=int(elapsed_fraction)
    elapsed_fraction=fmod(elapsed_fraction,1.0)
  direction=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).rotated(Vector3.UP,yaw).normalized()
  hero.position=ExplorationMotion.move(hero.position,direction*(6.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 4)*State.travel_multiplier()*delta,can_walk)
  if direction.length()>0: hero.rotation.y=lerp_angle(hero.rotation.y,atan2(-direction.x,-direction.z),minf(1,delta*10))
 State.remember_position(hero.position)
 Art.animate(hero,clock,direction.length()>0)
 wolf.position=wolf.position.lerp(hero.position+Vector3(0.7,0,1),minf(1,delta*4))
 wolf.visible=State.hero.companion.active
 Art.animate(wolf,clock,direction.length()>0)
 for i in range(enemies.size()):
  enemies[i].visible=not State.hero.journey.guards.has(i)
  Art.animate(enemies[i],clock,false)
 for i in range(seals.size()):
  seals[i].rotation.y=clock*0.3
  seals[i].visible=not State.hero.journey.seals.has(i)
 boss.visible=not State.hero.journey.boss
 Art.animate(boss,clock,false)
 chest.visible=not State.hero.journey.chest
 camera.update_view(hero.position+Vector3.UP,Vector3(sin(yaw)*cos(pitch)*8,-sin(pitch)*8,cos(yaw)*cos(pitch)*8),delta)
 gate.visible=State.hero.journey.seals.size()<2
 var context="[E] Interact · [Esc] Menu"
 if hero.position.distance_to(boss.position)<4 and boss.visible: context="Contact the Hollow Warden · Defend its charged attack"
 hud_layer.update_view(hero.position,"Rootbound Sanctuary · Seals %s/2 · Solve both chamber puzzles" % State.hero.journey.seals.size(),context,"",delta)
 if contact_grace<=0 and not auto_panel.active and not dialogue.active and not options.active and not pause_menu.get_parent().get_parent().visible and not puzzle_panel.get_parent().get_parent().visible and not encounter_busy:
  for index in range(enemies.size()):
   if enemies[index].visible and hero.position.distance_to(enemies[index].position)<1.25:
    start_battle("mossling",100+index)
    return
  if boss.visible and State.hero.journey.seals.size()==2 and hero.position.distance_to(boss.position)<2.5:
   start_battle("warden",200)
func interact():
 if auto_panel.active or dialogue.active or options.active or puzzle_panel.get_parent().get_parent().visible or pause_menu.get_parent().get_parent().visible: return
 if hero.position.z>-1.0:
  State.hero.journey.region="forest"
  State.remember_position(Forest.SHRINE+Vector3(0,0,3))
  State.save_game()
  get_tree().change_scene_to_file("res://scenes/world.tscn")
  return
 if chest.visible and hero.position.distance_to(chest.position)<2:
  State.hero.journey.chest=true
  State.hero.potions+=3
  State.restore()
  State.save_game()
  chest.hide()
  Sound.cue("heal")
  dialogue.lines=[["Hero","A pilgrim left supplies for the next traveler. Three potions, and enough light to restore our strength."]]
  dialogue.database["cache"]=dialogue.lines
  dialogue.show_id("cache")
  return
 for i in range(seals.size()):
  if hero.position.distance_to(seals[i].position)<2 and not State.hero.journey.seals.has(i):
   if not State.hero.journey.guards.has(i):
    start_battle("mossling",100+i)
   elif not State.hero.puzzles.solved.has("dials" if i==0 else "song"):
    open_puzzle(i)
   else:
    State.hero.journey.seals.append(i)
    State.save_game()
    seals[i].hide()
    Sound.cue("heal")
    dialogue.show_id("seal")
   return
 for i in range(enemies.size()):
  if enemies[i].visible and hero.position.distance_to(enemies[i].position)<2.5:
   start_battle("mossling",100+i)
   return
 if hero.position.distance_to(boss.position)<4 and not State.hero.journey.boss:
  if State.hero.journey.seals.size()<2: dialogue.show_id("boss_locked")
  else: dialogue.show_id("boss",func(): start_battle("warden",200))
func start_battle(species: String, id: int, force_normal:bool=false):
 if State.hero.hp<=0 or encounter_busy or auto_panel.active: return
 State.enemy_id=species
 State.encounter_id=id
 State.remember_position(hero.position)
 if species!="warden" and State.species_wins(species)>=10 and not force_normal:
  auto_panel.open(species,true)
  return
 encounter_busy=true
 get_tree().change_scene_to_file.call_deferred("res://scenes/battle.tscn")

func open_character(page: String):
 State.menu_page=page
 State.remember_position(hero.position)
 get_tree().change_scene_to_file("res://scenes/character.tscn")

func open_puzzle(index:int):
 puzzle_index=index
 for child in puzzle_panel.get_children():
  puzzle_panel.remove_child(child)
  child.queue_free()
 puzzle_panel.get_parent().get_parent().show()
 var solved=State.hero.puzzles.solved.has("dials" if index==0 else "song")
 UI.label(puzzle_panel,"THE SUNWARD DIALS" if index==0 else "THE WATERSONG BELLS").add_theme_font_size_override("font_size",25)
 UI.label(puzzle_panel,"Light returns to the seal. Close this page and press E to cleanse it." if solved else ("Inscription: 'The sun leads. The moon follows. The leaf rests last.'\nAlign the three dials from left to right. Each click rotates one symbol." if index==0 else "Inscription: 'Water wakes the dawn. Dawn stirs the leaves.'\nRing the three bells in that order. A wrong note clears the sequence."))
 if index==0:
  var symbols=["Seed","Sun","Leaf","Moon"]
  for dial in range(3):
   var dial_index=dial
   UI.button(puzzle_panel,"Dial %s: %s · rotate" % [dial+1,symbols[State.hero.puzzles.dials[dial]]],func():
    State.puzzle_dial(dial_index)
    Sound.cue("confirm")
    open_puzzle(0)).disabled=solved
 else:
  UI.label(puzzle_panel,"Harmony: %s / 3 notes" % State.hero.puzzles.sequence.size())
  for bell in range(3):
   var bell_index=bell
   UI.button(puzzle_panel,["Dawn bell","Leaf bell","Water bell"][bell],func():
    State.puzzle_note(bell_index)
    Sound.cue("confirm")
    open_puzzle(1)).disabled=solved
 UI.button(puzzle_panel,"Return to chamber",func(): puzzle_panel.get_parent().get_parent().hide())

extends Node3D
var hero: Node3D
var wolf: Node3D
var camera: Camera3D
var dialogue: Dialogue
var hud: Label
var objective: Label
var prompt: Label
var seals: Array[Node3D]=[]
var enemies: Array[Node3D]=[]
var floor_cells: Dictionary={}
var yaw=0.0
var pitch=-0.6
var clock=0.0
var boss: Node3D
var chest: Node3D
var pause_menu: VBoxContainer
var enemy_homes=[Vector3(-8,0,-10),Vector3(8,0,-10)]
func _ready():
 build_dungeon()
 hero=Art.actor("Hero",State.hero.equipment)
 add_child(hero)
 hero.position=State.return_position
 if not can_walk(hero.position): hero.position=Vector3.ZERO
 wolf=Art.actor("Wolf")
 add_child(wolf)
 wolf.position=hero.position+Vector3(1,0,1)
 camera=Camera3D.new()
 add_child(camera)
 camera.current=true
 dialogue=Dialogue.new()
 add_child(dialogue)
 var top=UI.panel(self,Vector2(16,16),Vector2(650,120))
 hud=UI.label(top,"")
 UI.label(top,"WASD · Shift sprint · Right mouse orbit · E interact · Escape menu")
 var journal=UI.panel(self,Vector2(890,16),Vector2(370,145))
 objective=UI.label(journal,"")
 prompt=UI.label(UI.panel(self,Vector2(300,640),Vector2(680,60)),"")
 pause_menu=UI.panel(self,Vector2(440,220),Vector2(400,250))
 pause_menu.get_parent().get_parent().hide()
 UI.button(pause_menu,"Resume",func(): pause_menu.get_parent().get_parent().hide())
 UI.button(pause_menu,"Save",func(): State.save_game())
 UI.button(pause_menu,"Music / sound",Sound.toggle)
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
 return floor_cells.has(Vector2i(floori((pos.x+1)/2),floori((pos.z+1)/2)))
func _unhandled_input(event):
 if dialogue.active: return
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  yaw-=event.relative.x*0.005
  pitch=clampf(pitch-event.relative.y*0.004,-1.05,-0.3)
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_E: interact()
   KEY_ESCAPE: pause_menu.get_parent().get_parent().visible=not pause_menu.get_parent().get_parent().visible
   KEY_F5: State.save_game()
func _process(delta):
 clock+=delta
 var direction=Vector3.ZERO
 if not dialogue.active and not pause_menu.get_parent().get_parent().visible:
  direction=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).rotated(Vector3.UP,yaw).normalized()
  var next=hero.position+direction*(6.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 4)*delta
  if can_walk(Vector3(next.x,0,hero.position.z)): hero.position.x=next.x
  if can_walk(Vector3(hero.position.x,0,next.z)): hero.position.z=next.z
  if direction.length()>0: hero.rotation.y=lerp_angle(hero.rotation.y,atan2(-direction.x,-direction.z),delta*10)
 State.remember_position(hero.position)
 Art.animate(hero,clock,direction.length()>0)
 wolf.position=wolf.position.lerp(hero.position+Vector3(0.7,0,1),minf(1,delta*4))
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
 camera.position=hero.position+Vector3(sin(yaw)*cos(pitch)*8,-sin(pitch)*8+1,cos(yaw)*cos(pitch)*8)
 camera.look_at(hero.position+Vector3.UP)
 hud.text="ROOTBOUND SANCTUARY\nLv %s · HP %s/%s · MP %s/%s · Potions %s" % [State.hero.level,State.hero.hp,State.stats().max_hp,State.hero.mp,State.stats().max_mp,State.hero.potions]
 objective.text="THE BELL BENEATH THE WOODS\nRoot seals: %s/2\n%s" % [State.hero.journey.seals.size(),"Return to Mira" if State.hero.journey.boss else "Cleanse the guardian's heart"]
 prompt.text="[E] Interact · Explore both side chambers · [Esc] Menu"
 if hero.position.distance_to(boss.position)<4 and boss.visible: prompt.text="[E] Face the Hollow Warden · Watch its charging attack!"
func interact():
 if dialogue.active or pause_menu.get_parent().get_parent().visible: return
 if hero.position.z>-1.0:
  State.hero.journey.region="forest"
  State.remember_position(Vector3(24,0,-10))
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
func start_battle(species: String, id: int):
 if State.hero.hp<=0: return
 State.enemy_id=species
 State.encounter_id=id
 State.return_position=hero.position
 get_tree().change_scene_to_file("res://scenes/battle.tscn")

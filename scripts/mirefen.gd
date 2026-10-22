extends Node3D
# First playable expansion, preserving the demo's combat, equipment, and character systems.
const RELIQUARY_GATE := Vector3(3, 0, -62)
const RETURN_GATE := Vector3(0, 0, 8)
const SHOP_POS := Vector3(-5, 0, -8)
const ARMOR_POS := Vector3(5, 0, -8)
const INN_POS := Vector3(0, 0, -11)
const ENCOUNTER_POS := [Vector3(-3, 0, -30), Vector3(3, 0, -42), Vector3(-3, 0, -48),Vector3(3,0,-53),Vector3(-3,0,-58)]
const ROYAL:=Vector3(-2,0,1)
const IONA:=Vector3(0,0,-16)
const SELLA:=Vector3(-3,0,-11)
const JORY:=Vector3(3,0,-15)
const SURVEYS:=[Vector3(-3,0,-25),Vector3(3,0,-39),Vector3(-3,0,-54)]
const REEDS:=[Vector3(5,0,-23),Vector3(-5,0,-33),Vector3(5,0,-45),Vector3(-5,0,-56)]
const SPECIES:=["mire_leech","bog_wisp","reed_stalker","reed_stalker","reed_stalker"]
var auto_panel:AutoBattlePanel
var pending_index:=0
var reeds:Array[Node3D]=[]
var hero: Node3D
var companion: Node3D
var camera: ExplorationCamera
var hud: ExplorationHUD
var dialogue: Dialogue
var options: OptionsPanel
var menu: VBoxContainer
var message := "Reedcross — Gateway to Mirefen Marsh"
var yaw := 0.0
var pitch := -0.45
var active_enemies: Array[Node3D] = []
var grace := 2.0
var clock := 0.0

func _ready() -> void:
 MirefenRules.campaign(State.hero)
 Art.environment_(self)
 MarshArt.atmosphere(self)
 _build_marsh()
 State.hero.journey.region = "mirefen"
 hero = Art.actor("Hero", State.hero.equipment)
 add_child(hero)
 hero.position = State.return_position
 companion = CompanionVisual.build(State.hero.companion.current)
 add_child(companion)
 for i in range(ENCOUNTER_POS.size()):
  var mob = Art.actor(str(JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))[SPECIES[i]].model))
  add_child(mob)
  mob.position = ENCOUNTER_POS[i]
  Art.sign_(mob, Vector3(0, 2.8, 0), str(JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))[SPECIES[i]].name))
  active_enemies.append(mob)
 camera = ExplorationCamera.new()
 add_child(camera)
 camera.current = true
 hud = ExplorationHUD.new()
 add_child(hud)
 for pos in [ROYAL,IONA,SELLA,JORY,SHOP_POS,ARMOR_POS,INN_POS]:hud.map.markers.append({"position":pos,"color":Color("e8cf83")})
 for pos in SURVEYS:hud.map.markers.append({"position":pos,"color":Color("7ad9d3")})
 dialogue = Dialogue.new()
 add_child(dialogue)
 options = OptionsPanel.new()
 add_child(options)
 menu = UI.panel(self, Vector2(430, 150), Vector2(430, 350))
 menu.get_parent().get_parent().hide()
 auto_panel=AutoBattlePanel.new()
 add_child(auto_panel)
 auto_panel.fight_requested.connect(func(): _normal_battle(pending_index))
 auto_panel.closed.connect(func():
  grace=3.0
  if State.hero.hp<=0:get_tree().change_scene_to_file.call_deferred(State.travel_scene()))
 Sound.theme_("woodland")
 MarshArt.ambience(self)

func _build_marsh() -> void:
 TownServices.signs(self,"mirefen")
 MarshArt.settlement(self)
 for entry in [[ROYAL,"King Aldren","Paladin","Male"],[IONA,"Warden Iona","Druid","Female"],[SELLA,"Healer Sella","Healer","Female"],[JORY,"Ferryman Jory","Ranger","Male"]]:
  MarshArt.npc(self,entry[0],entry[1],entry[2],entry[3])
 for i in SURVEYS.size():
  MarshArt.lantern(self,SURVEYS[i],"Survey stone %s [E]" % (i+1))
 for i in REEDS.size():
  var clump=Node3D.new()
  add_child(clump)
  clump.position=REEDS[i]
  for n in 5:Art.shape(clump,Vector3((n-2)*.13,.55,0),Vector3(.11,1.1,.11),Color("b8cfa7"),"cone")
  reeds.append(clump)
 Art.box(self, Vector3(0, -0.17, -28), Vector3(44, 0.25, 91), Color("667c58")).material_override = Art.surface(Color("7d8b65"), "grass", 15)
 for i in range(22):
  var z = -57.0 + i * 2.8
  var center=sin(z*.12)*1.1
  for plank in 7:
   Art.box(self,Vector3(center,.04,z+(plank-3)*.37),Vector3(4.2,.15,.34),Color("8e8063")).material_override=Art.surface(Color("9c8b69"),"wood",1)
  if i%2==0:
   for side in [-2.2,2.2]:Art.box(self,Vector3(center+side,.55,z),Vector3(.14,1.1,.14),Color("685d49"))
 for x in [-16.0, 16.0]:
  var water = Art.box(self, Vector3(x, -0.05, -34), Vector3(15, 0.09, 68), Color("4b777a"))
  var surface = ShaderMaterial.new()
  surface.shader = load("res://assets/shaders/water.gdshader")
  surface.set_shader_parameter("deep_color",Color("173e3e"))
  surface.set_shader_parameter("shallow_color",Color("50766a"))
  water.material_override = surface
 for i in range(65):
  var rng = RandomNumberGenerator.new()
  rng.seed = 4107 + i * 37
  var x = rng.randf_range(-20, 20)
  var z = rng.randf_range(-65, -17)
  if absf(x) < 5.5: continue
  Art.tree(self, Vector3(x, 0, z), rng.randf_range(0.6, 1.1))
 for pos in [Vector3(-8, 0, -5), Vector3(8, 0, -5), Vector3(-8, 0, -12), Vector3(8, 0, -12)]:
  VillageArt.cottage(self, pos)
 Art.sign_(self, RETURN_GATE + Vector3(0, 2.6, 0), "Road to Willowbrook [E]")
 Art.sign_(self, RELIQUARY_GATE + Vector3(0, 3.2, 0), "Sunken Reliquary [E]")
 for i in range(18):
  var z = -20.0 - i * 2.2
  for x in [-6.0, 6.0]:
   var point=Vector3(x+sin(i*1.9)*.5,0,z)
   for n in 3:
    var stem=point+Vector3((n-1)*.2,.65+float(n)*.1,0)
    Art.shape(self,stem,Vector3(.045,1.3,.045),Color("6f8060"),"cylinder")
    Art.shape(self,stem+Vector3(0,.6,0),Vector3(.13,.32,.13),Color("76644b"),"cylinder")

func _input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if event.keycode == KEY_ESCAPE and menu.get_parent().get_parent().visible:
  menu.get_parent().get_parent().hide()
  get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if dialogue.active or options.active or auto_panel.active: return
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  yaw -= event.relative.x * 0.005 * UserSettings.camera_sensitivity
  pitch = clampf(pitch - event.relative.y * 0.004 * UserSettings.camera_sensitivity, -1.1, -0.15)
 if not event is InputEventKey or not event.pressed or event.echo: return
 match event.keycode:
  KEY_E: interact()
  KEY_TAB: _character("inventory")
  KEY_I: _character("equipment")
  KEY_K: _character("skills")
  KEY_C: _character("companions")
  KEY_J: _character("journal")
  KEY_F5: State.save_game()
  KEY_F9:
   State.load_game()
   get_tree().change_scene_to_file(State.travel_scene())
  KEY_ESCAPE:
   menu.get_parent().get_parent().visible = not menu.get_parent().get_parent().visible
   _refresh_menu()

func _process(delta: float) -> void:
 clock += delta
 grace = maxf(0, grace - delta)
 var direction := Vector3.ZERO
 if not dialogue.active and not options.active and not menu.get_parent().get_parent().visible and not auto_panel.active:
  var input := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
  direction = input.rotated(Vector3.UP, yaw).normalized()
  var speed = (7.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.3) * State.travel_multiplier()
  var next = hero.position + direction * speed * delta
  hero.position=ExplorationMotion.move(hero.position,direction*speed*delta,walkable)
  if direction.length() > 0:
   hero.rotation.y = lerp_angle(hero.rotation.y, atan2(-direction.x, -direction.z), minf(1, delta * 12))
 State.remember_position(hero.position)
 Art.animate(hero, clock, direction.length() > 0)
 companion.visible = State.hero.companion.active
 var follow = hero.position + Vector3(1, 0, 1.4)
 var moving = companion.position.distance_to(follow) > 0.3
 companion.position = companion.position.lerp(follow, minf(1, delta * 4))
 Art.animate(companion, clock, moving)
 camera.update_view(hero.position + Vector3.UP * 1.2, Vector3(sin(yaw) * cos(pitch) * 8, -sin(pitch) * 8 + 0.3, cos(yaw) * cos(pitch) * 8), delta)
 for i in reeds.size():reeds[i].visible=not State.hero.campaign.reeds.has(i)
 for i in range(active_enemies.size()):
  active_enemies[i].visible = Time.get_ticks_msec() > int(State.cleared_until.get(2000 + i, 0))
  Art.animate(active_enemies[i], clock, false)
  if active_enemies[i].visible and hero.position.distance_to(active_enemies[i].position) < 1.5 and grace <= 0 and not dialogue.active and not menu.get_parent().get_parent().visible and not auto_panel.active and not options.active:
   if State.hero.hp > 0 and State.starter_ready():
    _battle(i)
    return
 hud.update_view(hero.position, MirefenRules.goal(State.hero), _prompt(), message, delta)

func walkable(pos:Vector3)->bool:
 if absf(pos.x)>20 or pos.z< -67 or pos.z>13:return false
 if pos.z< -18 and absf(pos.x)>6:return false
 for house in [Vector3(-8,0,-5),Vector3(8,0,-5),Vector3(-8,0,-12),Vector3(8,0,-12)]:
  if absf(pos.x-house.x)<2.5 and absf(pos.z-house.z)<2.4:return false
 return true
func _prompt() -> String:
 var door=TownServices.nearby("mirefen",hero.position)
 if not door.is_empty():return "[E] Enter "+door[2]
 for entry in [[ROYAL,"Meet King Aldren"],[IONA,"Speak with Warden Iona"],[SELLA,"Healer Sella · silverreed"],[JORY,"Ferryman Jory · causeway patrol"]]:
  if hero.position.distance_to(entry[0])<2.5:return "[E] "+entry[1]
 for pos in SURVEYS:
  if hero.position.distance_to(pos)<2:return "[E] Read the water survey"
 for i in REEDS.size():
  if hero.position.distance_to(REEDS[i])<2 and not State.hero.campaign.reeds.has(i):return "[E] Gather silverreed"
 if hero.position.distance_to(RETURN_GATE) < 3: return "[E] Travel to Willowbrook"
 if hero.position.distance_to(SHOP_POS) < 3: return "[E] Reedcross weapon trader"
 if hero.position.distance_to(ARMOR_POS) < 3: return "[E] Reedcross armorer"
 if hero.position.distance_to(INN_POS) < 3: return "[E] Inn directions · marked northeast house"
 if hero.position.distance_to(RELIQUARY_GATE) < 4: return "[E] Enter the Sunken Reliquary"
 return "Reedcross Marsh — follow the raised wooden road"

func _done() -> bool:
 return State.hero.get("campaign", {}).get("reliquary_cleared", false)

func interact() -> void:
 if dialogue.active or options.active or auto_panel.active or menu.get_parent().get_parent().visible:return
 var c=MirefenRules.campaign(State.hero)
 var door=TownServices.nearby("mirefen",hero.position)
 if not door.is_empty():
  TownServices.enter(get_tree(),"mirefen",door)
  return
 if hero.position.distance_to(ROYAL)<2.5:
  dialogue.show_id("marsh_royal",func():
   if not c.audience:
    c.audience=true
    State.award_gold(90,"Royal travel purse")
    State.save_game())
  return
 if hero.position.distance_to(IONA)<2.5:
  if c.reliquary_cleared:
   dialogue.show_id("marsh_complete" if c.reported else "marsh_after",func():
    if not c.reported:
     c.reported=true
     c.desert_clue=true
     State.award_xp(260)
     State.award_gold(200,"The Drowned Oath")
     State.grant_item("Fenwarden Pendant")
     State.save_game())
  elif not c.audience:message="Meet the king and his messenger in the southern square first."
  elif c.readings.size()==3:
   dialogue.show_id("marsh_key",func():
    c.sluice_key=true
    State.save_game())
  else:
   dialogue.show_id("marsh_iona",func():
    c.investigating=true
    State.save_game())
  return
 for entry in [[SELLA,"silverreed","marsh_reeds"],[JORY,"causeway","marsh_patrol"]]:
  if hero.position.distance_to(entry[0])<2.5:
   if State.claim_side_quest(entry[1]):message="Thank you! Gold and experience received."
   elif State.hero.side_quests.claimed.has(entry[1]):message="Your help has made Reedcross safer."
   else:
    State.accept_side_quest(entry[1])
    dialogue.show_id(entry[2])
   return
 for i in SURVEYS.size():
  if hero.position.distance_to(SURVEYS[i])<2:
   message="Survey %s: the current flows toward the sealed heart." % (i+1) if MirefenRules.collect(State.hero,"readings",i) else "Speak to Iona before taking readings, or this reading is already recorded."
   State.save_game()
   return
 for i in REEDS.size():
  if hero.position.distance_to(REEDS[i])<2 and MirefenRules.collect(State.hero,"reeds",i):
   State.hero.side_quests.silverreed=c.reeds.size()
   message="Silverreed collected · %s/4" % c.reeds.size()
   State.save_game()
   return
 if hero.position.distance_to(RETURN_GATE) < 3:
  _travel("forest", "res://scenes/world.tscn", Vector3(0, 0, 1))
 elif hero.position.distance_to(SHOP_POS) < 3 or hero.position.distance_to(ARMOR_POS) < 3:
  message="Visit the marked house doors for weapons and armor."
 elif hero.position.distance_to(INN_POS) < 3:
  message="The Lantern Rest inn is in the northeastern house. Rooms cost 24 gold."
 elif hero.position.distance_to(RELIQUARY_GATE) < 4:
  if not c.sluice_key:
   message="The door needs Iona’s sluice key. Investigate the survey stones first."
   return
  _travel("reliquary", "res://scenes/reliquary.tscn", Vector3(0, 0, 4))

func _travel(region: String, path: String, pos: Vector3) -> void:
 State.hero.journey.region = region
 State.remember_position(pos)
 State.save_game()
 get_tree().change_scene_to_file(path)

func _battle(index: int) -> void:
 pending_index=index
 State.enemy_id=SPECIES[index]
 State.encounter_id=2000+index
 State.remember_position(hero.position)
 if State.species_wins(State.enemy_id)>=10:auto_panel.open(State.enemy_id,true)
 else:_normal_battle(index)
func _normal_battle(index:int)->void:
 State.enemy_id = SPECIES[index]
 State.encounter_id = 2000 + index
 State.hero.journey.region = "mirefen"
 State.remember_position(hero.position)
 State.save_game()
 get_tree().change_scene_to_file("res://scenes/battle.tscn")

func _character(page: String) -> void:
 State.menu_page = page
 State.hero.journey.region = "mirefen"
 State.remember_position(hero.position)
 get_tree().change_scene_to_file("res://scenes/character.tscn")

func _refresh_menu() -> void:
 for child in menu.get_children():
  child.queue_free()
 UI.label(menu, "REEDCROSS TRAVEL MENU")
 UI.button(menu, "Inventory [Tab]", func(): _character("inventory"))
 UI.button(menu, "Equipment [I]", func(): _character("equipment"))
 UI.button(menu, "Class skills [K]", func(): _character("skills"))
 UI.button(menu, "Companion [C]", func(): _character("companions"))
 UI.button(menu, "Quest journal [J]", func(): _character("journal"))
 UI.button(menu, "Settings", options.open)
 UI.button(menu, "Save", func(): State.save_game())
 UI.button(menu, "Close", func(): menu.get_parent().get_parent().hide())

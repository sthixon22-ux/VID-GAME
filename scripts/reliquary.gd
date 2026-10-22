extends Node3D
# Dungeon 2: a small complete exploration loop with two water locks and a boss.
const EXIT := Vector3(0, 0, 5)
const WEST := Vector3(-6, 0, -14)
const EAST := Vector3(6, 0, -28)
const BOSS_GATE := Vector3(0, 0, -44)
const CACHE:=Vector3(-8,0,-23)
const SENTINEL:=Vector3(4,0,-34)
var water_surfaces:Array[Node3D]=[]
var west_wheel:Node3D
var east_wheel:Node3D
var sentinel:Node3D
var auto_panel:AutoBattlePanel
var grace:=2.0
var hero: Node3D
var companion: Node3D
var camera: ExplorationCamera
var hud: ExplorationHUD
var options: OptionsPanel
var message := "The Sunken Reliquary — old floodgates whisper beneath the water."
var yaw := 0.0
var pitch := -0.5
var elapsed := 0.0

func _ready() -> void:
 MirefenRules.campaign(State.hero)
 Art.environment_(self)
 MarshArt.atmosphere(self,true)
 _build()
 State.hero.journey.region = "reliquary"
 hero = Art.actor("Hero", State.hero.equipment)
 add_child(hero)
 hero.position = State.return_position
 companion = CompanionVisual.build(State.hero.companion.current)
 add_child(companion)
 camera = ExplorationCamera.new()
 add_child(camera)
 camera.current = true
 hud = ExplorationHUD.new()
 add_child(hud)
 for pos in [WEST,EAST,EXIT]:hud.map.markers.append({"position":pos,"color":Color("7ad9d3")})
 hud.map.markers.append({"position":BOSS_GATE,"color":Color("d5887d")})
 options = OptionsPanel.new()
 add_child(options)
 auto_panel=AutoBattlePanel.new()
 add_child(auto_panel)
 auto_panel.fight_requested.connect(_sentinel_battle)
 auto_panel.closed.connect(func():
  grace=3
  if State.hero.hp<=0:get_tree().change_scene_to_file.call_deferred(State.travel_scene()))
 sentinel=Art.actor("DrownedSentinel")
 add_child(sentinel)
 sentinel.position=SENTINEL
 _sync_water(false)
 Sound.theme_("sanctuary")

func _build() -> void:
 Art.box(self, Vector3(0, -0.3, -21), Vector3(26, 0.5, 64), Color("6d7166")).material_override = Art.surface(Color("858981"), "stone", 12)
 for x in [-12.0, 12.0]:
  Art.box(self, Vector3(x, 1.7, -21), Vector3(0.8, 3.4, 63), Color("677c77")).material_override=Art.surface(Color("75857e"),"stone",8)
 for z in [-51.0, 8.0]:
  Art.box(self, Vector3(0, 1.7, z), Vector3(25, 3.4, 0.8), Color("677c77")).material_override=Art.surface(Color("75857e"),"stone",8)
 for z in [-6.0, -21.0, -36.0]:
  var water = Art.box(self, Vector3(0, 0.12, z), Vector3(20, 0.05, 7), Color("47757c"))
  var material = ShaderMaterial.new()
  material.shader = load("res://assets/shaders/water.gdshader")
  material.set_shader_parameter("deep_color",Color("163c45"))
  material.set_shader_parameter("shallow_color",Color("426970"))
  water.material_override = material
  water_surfaces.append(water)
 # Four chambers: vestibule, drained west basin, east gallery and oath heart.
 for z in [-10.0,-25.0,-39.0]:
  for x in [-8.0,8.0]:
   var wall=Art.box(self,Vector3(x,1.3,z),Vector3(6,2.6,.65),Color("647c79"))
   wall.material_override=Art.surface(Color("97a6a0"),"stone",3)
   CameraObstacles.box(self,wall.position,Vector3(6,2.6,.65))
 for z in [-10.0,-25.0,-39.0]:
  for x in [-4.5,4.5]:
   Art.box(self,Vector3(x,2.3,z),Vector3(.5,4.6,.8),Color("8c9d91")).material_override=Art.surface(Color("8c9d91"),"stone",2)
  Art.box(self,Vector3(0,4.4,z),Vector3(9.5,.45,.8),Color("9aab99")).material_override=Art.surface(Color("9aab99"),"stone",2)
 for z in [-3.0,-17.0,-31.0,-44.0]:
  for x in [-9.0,9.0]:MarshArt.lantern(self,Vector3(x,0,z))
 Art.sign_(self,Vector3(0,2.4,-8),"EMPTY the bowl · TURN the river · QUIET the heart")
 Art.sign_(self,Vector3(-8,2.4,-20),"Dry stone remembers the ferryman's hidden tithe [E]")
 Art.box(self,CACHE+Vector3(0,.4,0),Vector3(1.4,.8,.8),Color("a29159"))
 var ring=Art.shape(self,Vector3(0,.05,-45),Vector3(10,.15,10),Color("6aa6a3"),"cylinder")
 ring.material_override=Art.surface(Color("a4bdac"),"stone",4)
 for p in [WEST, EAST]:
  Art.shape(self, p + Vector3(0, 0.9, 0), Vector3(1.7, 1.8, 1.7), Color("a9bbaa"), "cylinder")
  var wheel=Art.shape(self,p+Vector3(0,1.9,0),Vector3(1.3,.2,1.3),Color("b5a577"),"cylinder")
  wheel.rotation.x=PI/2
  if p==WEST:west_wheel=wheel
  else:east_wheel=wheel
 Art.sign_(self, EXIT + Vector3(0, 2.8, 0), "Return to Mirefen [E]")
 Art.sign_(self, WEST + Vector3(0, 3.6, 0), "Western floodgate [E]")
 Art.sign_(self, EAST + Vector3(0, 3.6, 0), "Eastern floodgate [E]")
 Art.sign_(self, BOSS_GATE + Vector3(0, 3.8, 0), "Heart of the Reliquary [E]")
 for i in range(16):
  var p = Vector3(-10 if i % 2 == 0 else 10, 0, -47 + float(i) * 3)
  Art.shape(self, p + Vector3(0, 1.0, 0), Vector3(0.9, 2.0, 0.9), Color("a3aea0"), "cylinder")

func _unhandled_input(event: InputEvent) -> void:
 if options.active or auto_panel.active: return
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  yaw -= event.relative.x * 0.005 * UserSettings.camera_sensitivity
  pitch = clampf(pitch - event.relative.y * 0.004 * UserSettings.camera_sensitivity, -1.1, -0.15)
 if not event is InputEventKey or not event.pressed or event.echo: return
 match event.keycode:
  KEY_E: interact()
  KEY_I: _character("equipment")
  KEY_K: _character("skills")
  KEY_C: _character("companions")
  KEY_J: _character("journal")
  KEY_TAB: _character("inventory")
  KEY_F5: State.save_game()
  KEY_F9:
   State.load_game()
   get_tree().change_scene_to_file(State.travel_scene())
  KEY_ESCAPE: options.open()

func _process(delta: float) -> void:
 if not options.active and not auto_panel.active:
  var orbit=CameraOrbit.step(yaw,pitch,delta)
  yaw=orbit.x
  pitch=orbit.y
 elapsed += delta
 grace=maxf(0,grace-delta)
 var direction := Vector3.ZERO
 if not options.active and not auto_panel.active:
  var input := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
  direction = input.rotated(Vector3.UP, yaw).normalized()
  var next = hero.position + direction * (7.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.3) * delta
  hero.position=ExplorationMotion.move(hero.position,next-hero.position,walkable)
  if direction.length() > 0:
   hero.rotation.y = lerp_angle(hero.rotation.y, atan2(-direction.x, -direction.z), minf(1, delta * 12))
 State.remember_position(hero.position)
 Art.animate(hero, elapsed, direction.length() > 0)
 companion.visible = State.hero.companion.active
 var follow = hero.position + Vector3(1, 0, 1.5)
 var moving = companion.position.distance_to(follow) > 0.4
 companion.position = companion.position.lerp(follow, minf(1, delta * 4))
 Art.animate(companion, elapsed, moving)
 camera.update_view(hero.position + Vector3.UP * 1.2, Vector3(sin(yaw) * cos(pitch) * 8, -sin(pitch) * 8 + 0.3, cos(yaw) * cos(pitch) * 8), delta)
 sentinel.visible=Time.get_ticks_msec()>int(State.cleared_until.get(2200,0))
 Art.animate(sentinel,elapsed,false)
 if sentinel.visible and grace<=0 and not options.active and not auto_panel.active and hero.position.distance_to(SENTINEL)<1.5 and State.hero.hp>0:
  State.enemy_id="drowned_sentinel"
  State.encounter_id=2200
  State.remember_position(hero.position)
  if State.species_wins("drowned_sentinel")>=10:auto_panel.open("drowned_sentinel",true)
  else:_sentinel_battle()
  return
 hud.update_view(hero.position, MirefenRules.goal(State.hero), _prompt(), message, delta)

func _campaign() -> Dictionary:
 return MirefenRules.campaign(State.hero)
func walkable(pos:Vector3)->bool:
 if absf(pos.x)>=11 or pos.z>=7 or pos.z<=-49:return false
 var c=_campaign()
 if pos.z< -18 and not c.reliquary_west:return false
 if pos.z< -39 and not _open():return false
 for z in [-10.0,-25.0,-39.0]:
  if absf(pos.z-z)<.65 and absf(pos.x)>4.8:return false
 return true
func _sync_water(animate:bool=true):
 var c=_campaign()
 for i in water_surfaces.size():
  var target=.12
  if (i<=1 and c.reliquary_west) or (i==2 and c.reliquary_east):target=-1.5
  if animate:create_tween().tween_property(water_surfaces[i],"position:y",target,1.5)
  else:water_surfaces[i].position.y=target
 if west_wheel:west_wheel.rotation.z=PI if c.reliquary_west else 0
 if east_wheel:east_wheel.rotation.z=PI if c.reliquary_east else 0
func _sentinel_battle():
 State.enemy_id="drowned_sentinel"
 State.encounter_id=2200
 State.remember_position(hero.position)
 State.save_game()
 get_tree().change_scene_to_file.call_deferred("res://scenes/battle.tscn")

func _open() -> bool:
 var c = _campaign()
 return c.get("reliquary_west", false) and c.get("reliquary_east", false)

func _prompt() -> String:
 if hero.position.distance_to(CACHE)<2.5:return "[E] Search the drained cache"
 if hero.position.distance_to(EXIT) < 3: return "[E] Return to Reedcross"
 if hero.position.distance_to(WEST) < 3: return "[E] Open western floodgate"
 if hero.position.distance_to(EAST) < 3: return "[E] Open eastern floodgate"
 if hero.position.distance_to(BOSS_GATE) < 4: return "[E] Confront the reliquary keeper"
 return "Follow the flooded corridors. Each valve releases an ancient seal."

func interact() -> void:
 if options.active or auto_panel.active:return
 if hero.position.distance_to(EXIT) < 3:
  _travel("mirefen", "res://scenes/mirefen.tscn", Vector3(0, 0, -58))
  return
 var c = _campaign()
 if hero.position.distance_to(CACHE)<2.5:
  if not c.reliquary_west:message="The cache is submerged."
  elif c.cache:message="The ferryman’s cache is empty."
  else:
   c.cache=true
   State.award_gold(75,"Ferryman’s hidden tithe")
   State.hero.items.ether+=1
   State.hero.potions+=2
   message="Found 75 gold, an ether and two potions."
 elif hero.position.distance_to(WEST)<3:message=MirefenRules.valve(State.hero,true)
 elif hero.position.distance_to(EAST)<3:message=MirefenRules.valve(State.hero,false)
 elif hero.position.distance_to(BOSS_GATE) < 4:
  if not _open():
   message = "Two ancient floodgates still bind the reliquary."
  elif c.reliquary_cleared:
   message = "The keeper rests. A fragment of the old covenant remains."
  else:
   State.enemy_id = "reliquary_keeper"
   State.encounter_id = 2300
   State.hero.journey.region = "reliquary"
   State.remember_position(hero.position)
   State.save_game()
   get_tree().change_scene_to_file("res://scenes/battle.tscn")
   return
 _sync_water()
 State.save_game()

func _travel(region: String, path: String, pos: Vector3) -> void:
 State.hero.journey.region = region
 State.remember_position(pos)
 State.save_game()
 get_tree().change_scene_to_file(path)

func _character(page: String) -> void:
 State.menu_page = page
 State.remember_position(hero.position)
 get_tree().change_scene_to_file("res://scenes/character.tscn")

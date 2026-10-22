extends Node3D
# Dungeon 2: a small complete exploration loop with two water locks and a boss.
const EXIT := Vector3(0, 0, 5)
const WEST := Vector3(-6, 0, -14)
const EAST := Vector3(6, 0, -28)
const BOSS_GATE := Vector3(0, 0, -44)
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
 Art.environment_(self)
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
 options = OptionsPanel.new()
 add_child(options)
 Sound.theme_("woodland")

func _build() -> void:
 Art.box(self, Vector3(0, -0.3, -21), Vector3(26, 0.5, 64), Color("6d7166")).material_override = Art.surface(Color("858981"), "stone", 3)
 for x in [-12.0, 12.0]:
  Art.box(self, Vector3(x, 1.7, -21), Vector3(0.8, 3.4, 63), Color("677c77"))
 for z in [-51.0, 8.0]:
  Art.box(self, Vector3(0, 1.7, z), Vector3(25, 3.4, 0.8), Color("677c77"))
 for z in [-6.0, -21.0, -36.0]:
  var water = Art.box(self, Vector3(0, -0.11, z), Vector3(20, 0.05, 7), Color("47757c"))
  var material = ShaderMaterial.new()
  material.shader = load("res://assets/shaders/water.gdshader")
  water.material_override = material
 for p in [WEST, EAST]:
  Art.shape(self, p + Vector3(0, 0.9, 0), Vector3(1.7, 1.8, 1.7), Color("a9bbaa"), "cylinder")
  Art.shape(self, p + Vector3(0, 2, 0), Vector3(0.7, 1, 0.7), Color("5bafd1"), "cone")
 Art.sign_(self, EXIT + Vector3(0, 2.8, 0), "Return to Mirefen [E]")
 Art.sign_(self, WEST + Vector3(0, 3.6, 0), "Western floodgate [E]")
 Art.sign_(self, EAST + Vector3(0, 3.6, 0), "Eastern floodgate [E]")
 Art.sign_(self, BOSS_GATE + Vector3(0, 3.8, 0), "Heart of the Reliquary [E]")
 for i in range(16):
  var p = Vector3(-10 if i % 2 == 0 else 10, 0, -47 + float(i) * 3)
  Art.shape(self, p + Vector3(0, 1.0, 0), Vector3(0.9, 2.0, 0.9), Color("a3aea0"), "cylinder")

func _unhandled_input(event: InputEvent) -> void:
 if options.active: return
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
 elapsed += delta
 var direction := Vector3.ZERO
 if not options.active:
  var input := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
  direction = input.rotated(Vector3.UP, yaw).normalized()
  var next = hero.position + direction * (7.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.3) * delta
  if absf(next.x) < 11 and next.z < 7 and next.z > -49 and (_open() or next.z > -39):
   hero.position = next
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
 hud.update_view(hero.position, "Open both floodgates, then restore the reliquary", _prompt(), message, delta)

func _campaign() -> Dictionary:
 if not State.hero.has("campaign"):
  State.hero.campaign = {"reliquary_west": false, "reliquary_east": false, "reliquary_cleared": false}
 return State.hero.campaign

func _open() -> bool:
 var c = _campaign()
 return c.get("reliquary_west", false) and c.get("reliquary_east", false)

func _prompt() -> String:
 if hero.position.distance_to(EXIT) < 3: return "[E] Return to Reedcross"
 if hero.position.distance_to(WEST) < 3: return "[E] Open western floodgate"
 if hero.position.distance_to(EAST) < 3: return "[E] Open eastern floodgate"
 if hero.position.distance_to(BOSS_GATE) < 4: return "[E] Confront the reliquary keeper"
 return "Follow the flooded corridors. Each valve releases an ancient seal."

func interact() -> void:
 if hero.position.distance_to(EXIT) < 3:
  _travel("mirefen", "res://scenes/mirefen.tscn", Vector3(0, 0, -58))
  return
 var c = _campaign()
 if hero.position.distance_to(WEST) < 3 and not c.reliquary_west:
  c.reliquary_west = true
  message = "The western sluice opens; the water recedes."
 elif hero.position.distance_to(EAST) < 3 and not c.reliquary_east:
  c.reliquary_east = true
  message = "The eastern sluice opens; the inner chamber is accessible."
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

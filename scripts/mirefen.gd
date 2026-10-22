extends Node3D
# First playable expansion, preserving the demo's combat, equipment, and character systems.
const RELIQUARY_GATE := Vector3(3, 0, -62)
const RETURN_GATE := Vector3(0, 0, 8)
const SHOP_POS := Vector3(-5, 0, -8)
const ARMOR_POS := Vector3(5, 0, -8)
const INN_POS := Vector3(0, 0, -11)
const ENCOUNTER_POS := [Vector3(-8, 0, -28), Vector3(6, 0, -40), Vector3(-6, 0, -52)]
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
 Art.environment_(self)
 _build_marsh()
 State.hero.journey.region = "mirefen"
 hero = Art.actor("Hero", State.hero.equipment)
 add_child(hero)
 hero.position = State.return_position
 companion = CompanionVisual.build(State.hero.companion.current)
 add_child(companion)
 for i in range(ENCOUNTER_POS.size()):
  var mob = Art.actor("Mossling")
  add_child(mob)
  mob.position = ENCOUNTER_POS[i]
  Art.sign_(mob, Vector3(0, 2.8, 0), "Marsh Mossling")
  active_enemies.append(mob)
 camera = ExplorationCamera.new()
 add_child(camera)
 camera.current = true
 hud = ExplorationHUD.new()
 add_child(hud)
 dialogue = Dialogue.new()
 add_child(dialogue)
 options = OptionsPanel.new()
 add_child(options)
 menu = UI.panel(self, Vector2(430, 150), Vector2(430, 350))
 menu.get_parent().get_parent().hide()
 Sound.theme_("woodland")

func _build_marsh() -> void:
 Art.box(self, Vector3(0, -0.17, -28), Vector3(44, 0.25, 91), Color("667c58")).material_override = Art.surface(Color("7d8b65"), "grass", 15)
 for i in range(22):
  var z = -57.0 + i * 2.8
  Art.box(self, Vector3(0, 0.04, z), Vector3(4.2, 0.15, 2.3), Color("9c8b69")).material_override = Art.surface(Color("9c8b69"), "wood", 2)
 for x in [-16.0, 16.0]:
  var water = Art.box(self, Vector3(x, -0.05, -34), Vector3(15, 0.09, 68), Color("4b777a"))
  var surface = ShaderMaterial.new()
  surface.shader = load("res://assets/shaders/water.gdshader")
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
 Art.sign_(self, SHOP_POS + Vector3(0, 2.7, 0), "Reedcross weapon trader [E]")
 Art.sign_(self, ARMOR_POS + Vector3(0, 2.7, 0), "Reedcross armorer [E]")
 Art.sign_(self, INN_POS + Vector3(0, 2.7, 0), "Reedcross inn [E]")
 Art.sign_(self, RELIQUARY_GATE + Vector3(0, 3.2, 0), "Sunken Reliquary [E]")
 for i in range(18):
  var z = -20.0 - i * 2.2
  for x in [-6.0, 6.0]:
   Art.shape(self, Vector3(x + sin(i * 1.9), 0.7, z), Vector3(0.15, 1.5, 0.15), Color("7c9371"), "cone")

func _input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if event.keycode == KEY_ESCAPE and menu.get_parent().get_parent().visible:
  menu.get_parent().get_parent().hide()
  get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if dialogue.active or options.active: return
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
 if not dialogue.active and not options.active and not menu.get_parent().get_parent().visible:
  var input := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
  direction = input.rotated(Vector3.UP, yaw).normalized()
  var speed = (7.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.3) * State.travel_multiplier()
  var next = hero.position + direction * speed * delta
  if absf(next.x) < 21 and next.z > -70 and next.z < 15:
   hero.position = next
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
 for i in range(active_enemies.size()):
  active_enemies[i].visible = Time.get_ticks_msec() > int(State.cleared_until.get(2000 + i, 0))
  Art.animate(active_enemies[i], clock, false)
  if active_enemies[i].visible and hero.position.distance_to(active_enemies[i].position) < 1.5 and grace <= 0 and not dialogue.active and not menu.get_parent().get_parent().visible:
   if State.hero.hp > 0 and State.starter_ready():
    _battle(i)
    return
 hud.update_view(hero.position, "Explore the Sunken Reliquary" if not _done() else "Return to Reedcross — reliquary restored", _prompt(), message, delta)

func _prompt() -> String:
 if hero.position.distance_to(RETURN_GATE) < 3: return "[E] Travel to Willowbrook"
 if hero.position.distance_to(SHOP_POS) < 3: return "[E] Reedcross weapon trader"
 if hero.position.distance_to(ARMOR_POS) < 3: return "[E] Reedcross armorer"
 if hero.position.distance_to(INN_POS) < 3: return "[E] Rest at the inn"
 if hero.position.distance_to(RELIQUARY_GATE) < 4: return "[E] Enter the Sunken Reliquary"
 return "Reedcross Marsh — follow the raised wooden road"

func _done() -> bool:
 return State.hero.get("campaign", {}).get("reliquary_cleared", false)

func interact() -> void:
 if dialogue.active or menu.get_parent().get_parent().visible: return
 if hero.position.distance_to(RETURN_GATE) < 3:
  _travel("forest", "res://scenes/world.tscn", Vector3(0, 0, 1))
 elif hero.position.distance_to(SHOP_POS) < 3 or hero.position.distance_to(ARMOR_POS) < 3:
  # Reuse the existing shop and item ownership rules while regional inventories are developed.
  _character("shop")
 elif hero.position.distance_to(INN_POS) < 3:
  State.restore()
  State.save_game()
  message = "You rest at the Reedcross inn. HP and MP restored."
 elif hero.position.distance_to(RELIQUARY_GATE) < 4:
  _travel("reliquary", "res://scenes/reliquary.tscn", Vector3(0, 0, 4))

func _travel(region: String, path: String, pos: Vector3) -> void:
 State.hero.journey.region = region
 State.remember_position(pos)
 State.save_game()
 get_tree().change_scene_to_file(path)

func _battle(index: int) -> void:
 State.enemy_id = "mossling"
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

extends Node3D
var name_field: LineEdit
var primary="Paladin"
var sex="Female"
var sex_picker:OptionButton
var skin_title:Label
var skin=0
var hair=0
var dye=0
var actor: Node3D
var secondary1: OptionButton
var secondary2: OptionButton
var details: Label
var class_picker: OptionButton
var message: Label
var clock=0.0
func _ready():
 Art.environment_(self)
 actor=Node3D.new()
 add_child(actor)
 actor.position=Vector3(2.8,0,0)
 actor.rotation.y=PI+0.3
 var camera=Camera3D.new()
 add_child(camera)
 camera.position=Vector3(1.2,1.7,4)
 camera.fov=45
 camera.look_at(Vector3(1.2,1,0))
 camera.current=true
 var menu=UI.panel(self,Vector2(36,25),Vector2(660,595))
 UI.label(menu,"CREATE YOUR HERO").add_theme_font_size_override("font_size",30)
 UI.label(menu,"The Bell Beneath the Woods · a complete short adventure")
 UI.label(menu,"Name")
 name_field=LineEdit.new()
 name_field.max_length=20
 name_field.placeholder_text="Traveler"
 name_field.custom_minimum_size=Vector2(0,36)
 menu.add_child(name_field)
 var body_row=HBoxContainer.new()
 menu.add_child(body_row)
 UI.label(body_row,"Character: ").custom_minimum_size=Vector2(180,0)
 sex_picker=OptionButton.new()
 for value in ["Male","Female"]:sex_picker.add_item(value)
 sex_picker.select(1)
 sex_picker.item_selected.connect(func(index):select_sex(sex_picker.get_item_text(index)))
 body_row.add_child(sex_picker)
 UI.label(menu,"Choose your PRIMARY class")
 class_picker=OptionButton.new()
 for class_ in State.classes: class_picker.add_item(class_)
 class_picker.item_selected.connect(func(index): select_class(class_picker.get_item_text(index)))
 menu.add_child(class_picker)
 var secondary_row=HBoxContainer.new()
 menu.add_child(secondary_row)
 UI.label(secondary_row,"Secondary classes: ")
 secondary1=OptionButton.new()
 secondary2=OptionButton.new()
 secondary_row.add_child(secondary1)
 secondary_row.add_child(secondary2)
 secondary1.item_selected.connect(func(index): update_secondaries(secondary1.get_item_text(index)); refresh_stats())
 secondary2.item_selected.connect(func(_index): refresh_stats())
 details=UI.label(menu,"")
 details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 details.custom_minimum_size=Vector2(580,135)
 skin_title=UI.label(menu,"")
 skin_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 appearance_choice(menu,"Skin tone",["Warm","Bronze","Deep"],func(index): skin=index; update_preview())
 appearance_choice(menu,"Hair color",["Chestnut","Golden","Silver"],func(index): hair=index; update_preview())
 appearance_choice(menu,"Outfit tint",["Class colors","Forest tint","Berry tint"],func(index): dye=index; update_preview())
 UI.label(menu,"You arrive unequipped with 120 gold and 3 potions.\nEnter the western weapon shop for your first gear.\nMira lends you a wolf; choose your own after the quest.")
 message=UI.label(menu,"")
 var footer=UI.panel(self,Vector2(36,630),Vector2(660,75))
 var actions=HBoxContainer.new()
 footer.add_child(actions)
 UI.button(actions,"Begin adventure",begin).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 UI.button(actions,"Back to title",func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
 select_class(primary)
 Sound.theme_("woodland")
func appearance_choice(parent: Node, label: String, values: Array, callback: Callable):
 var row=HBoxContainer.new()
 parent.add_child(row)
 UI.label(row,label+": ").custom_minimum_size=Vector2(180,0)
 var option=OptionButton.new()
 for value in values: option.add_item(value)
 option.item_selected.connect(callback)
 row.add_child(option)
func select_class(value: String):
 primary=value
 class_picker.select(State.classes.keys().find(value))
 update_secondaries()
 refresh_stats()
 update_preview()
func select_sex(value:String):
 if value not in ["Male","Female"]:return
 sex=value
 sex_picker.select(0 if sex=="Male" else 1)
 update_preview()
func refresh_stats():
 if secondary1.selected<0 or secondary2.selected<0: return
 var secondaries=[secondary1.get_item_text(secondary1.selected),secondary2.get_item_text(secondary2.selected)]
 var combined=GameRules.combined_stats(State.classes,primary,secondaries,1)
 var future=GameRules.combined_stats(State.classes,primary,secondaries,10)
 var profs:Array=[]
 for role in [primary]+secondaries:
  for family in State.classes[role].proficiencies:
   if not profs.has(family): profs.append(family)
 details.text="%s / %s / %s\n60%% primary + 20%% each secondary. Roles are LOCKED for this demo.\nLevel 1: %s\nLevel 10: %s\nWeapons: %s" % [primary,secondaries[0],secondaries[1],GameRules.summary(combined),GameRules.summary(future),", ".join(profs)]
func update_preview():
 var appearance={"skin":skin,"hair":hair,"dye":dye,"sex":sex,"class":primary}
 var pos=actor.position
 actor.queue_free()
 actor=HeroVisual.new(State.hero.equipment,appearance)
 add_child(actor)
 actor.position=pos
 actor.rotation.y=PI+0.3
 var look=HeroSkinBook.profile(primary,sex)
 skin_title.text="%s · %s %s\nCosmetic class outfit. Start without equipped gear." % [look.title,sex,primary]
func begin():
 if State.create_hero(name_field.text,primary,skin,hair,dye,[secondary1.get_item_text(secondary1.selected),secondary2.get_item_text(secondary2.selected)],sex): get_tree().change_scene_to_file("res://scenes/world.tscn")
 else: message.text="Could not save your character. "+State.save_notice
func _process(delta):
 clock+=delta
 if actor: Art.animate(actor,clock,false)

func update_secondaries(first: String=""):
 var available=State.classes.keys().filter(func(value): return value!=primary)
 if first.is_empty() or not available.has(first): first=State.classes[primary].recommended_secondary[0]
 secondary1.clear()
 secondary2.clear()
 for value in available:
  secondary1.add_item(value)
  if value!=first: secondary2.add_item(value)
 secondary1.select(available.find(first))
 var second=State.classes[primary].recommended_secondary[1]
 for index in range(secondary2.item_count):
  if secondary2.get_item_text(index)==second: secondary2.select(index); break
 if secondary2.selected<0: secondary2.select(0)

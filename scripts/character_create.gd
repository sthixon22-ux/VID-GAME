extends Node3D
var name_field: LineEdit
var primary="Paladin"
var skin=0
var hair=0
var dye=0
var actor: Node3D
var secondary1: OptionButton
var secondary2: OptionButton
var details: Label
var class_buttons: Dictionary={}
var message: Label
var clock=0.0
func _ready():
 Art.environment_(self)
 actor=Art.actor("Hero",State.hero.equipment)
 add_child(actor)
 actor.position=Vector3(2.8,0,0)
 actor.rotation.y=PI+0.3
 var camera=Camera3D.new()
 add_child(camera)
 camera.position=Vector3(1.2,1.7,4)
 camera.fov=45
 camera.look_at(Vector3(1.2,1,0))
 camera.current=true
 var menu=UI.panel(self,Vector2(36,25),Vector2(660,665))
 UI.label(menu,"CREATE YOUR HERO").add_theme_font_size_override("font_size",30)
 UI.label(menu,"The Bell Beneath the Woods · a complete short adventure")
 UI.label(menu,"Name")
 name_field=LineEdit.new()
 name_field.max_length=20
 name_field.placeholder_text="Traveler"
 name_field.custom_minimum_size=Vector2(0,36)
 menu.add_child(name_field)
 UI.label(menu,"Choose your PRIMARY class")
 var row=HBoxContainer.new()
 menu.add_child(row)
 for class_ in State.classes:
  var value: String=class_
  class_buttons[class_]=UI.button(row,class_,func(): select_class(value))
 var secondary_row=HBoxContainer.new()
 menu.add_child(secondary_row)
 UI.label(secondary_row,"Secondary classes: ")
 secondary1=OptionButton.new()
 secondary2=OptionButton.new()
 secondary_row.add_child(secondary1)
 secondary_row.add_child(secondary2)
 secondary1.item_selected.connect(func(index): update_secondaries(secondary1.get_item_text(index)))
 details=UI.label(menu,"")
 details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 details.custom_minimum_size=Vector2(580,75)
 appearance_choice(menu,"Skin tone",["Warm","Bronze","Deep"],func(index): skin=index; update_preview())
 appearance_choice(menu,"Hair color",["Chestnut","Golden","Silver"],func(index): hair=index; update_preview())
 appearance_choice(menu,"Travel clothes",["River blue","Forest green","Berry red"],func(index): dye=index; update_preview())
 UI.label(menu,"You arrive UNEQUIPPED, with 120 gold and 3 potions.\nBuy your first sword, shield and armor at the village outfitter.\nMira lends you a wolf for the quest; choose your own companion afterward.")
 message=UI.label(menu,"")
 UI.button(menu,"Begin adventure",begin)
 UI.button(menu,"Back to title",func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
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
 for key in class_buttons: class_buttons[key].disabled=key==value
 update_secondaries()
 details.text=State.classes[value].description+"\nAll three grant skills. Only your primary class can use its learned mythic."
func update_preview():
 State.hero.profile.skin=skin
 State.hero.profile.hair=hair
 State.hero.profile.dye=dye
 var pos=actor.position
 actor.queue_free()
 actor=Art.actor("Hero",State.hero.equipment)
 add_child(actor)
 actor.position=pos
 actor.rotation.y=PI+0.3
func begin():
 if State.create_hero(name_field.text,primary,skin,hair,dye,[secondary1.get_item_text(secondary1.selected),secondary2.get_item_text(secondary2.selected)]): get_tree().change_scene_to_file("res://scenes/world.tscn")
 else: message.text="Could not save your character. "+State.save_notice
func _process(delta):
 clock+=delta
 if actor: Art.animate(actor,clock,false)

func update_secondaries(first: String=""):
 var available=State.classes.keys().filter(func(value): return value!=primary)
 if first.is_empty() or not available.has(first): first=available[0]
 secondary1.clear()
 secondary2.clear()
 for value in available:
  secondary1.add_item(value)
  if value!=first: secondary2.add_item(value)
 secondary1.select(available.find(first))
 secondary2.select(0)

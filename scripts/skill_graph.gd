class_name SkillGraph
extends Control
signal selected(id: String)
var class_name_="Paladin"
var family=""
var nodes: Array=[]
var buttons: Dictionary={}
var selected_id="oath"
var learned: Array=[]
var tint=Color("d8bc78")
func configure(class_: String):
 class_name_=class_
 family=""
 nodes=State.classes[class_].nodes
 learned=State.hero.skills[class_]
 tint=Color(State.classes[class_].color)
 build()
func configure_weapon(type_: String):
 family=type_
 nodes=State.weapon_trees[type_]
 learned=State.hero.weapon_skills[type_]
 tint=Color("9dc6df")
 build()
func build():
 for child in get_children(): child.queue_free()
 buttons.clear()
 for node in nodes:
  var id: String=node.id
  var button=Button.new()
  button.custom_minimum_size=Vector2(162,62)
  var locked=State.hero.level<int(node.level_required)
  button.text=node.name+"\n"+("LEARNED" if learned.has(id) else "Lv %s · %s SP" % [int(node.level_required),int(node.cost)])
  button.tooltip_text=node.description
  var style=StyleBoxFlat.new()
  style.bg_color=Color("544a32") if learned.has(id) else (Color("172334") if locked else Color("1d3048"))
  style.border_color=Color("495565") if locked else tint
  style.set_border_width_all(2)
  style.set_corner_radius_all(8)
  button.add_theme_stylebox_override("normal",style)
  button.add_theme_font_size_override("font_size",14)
  button.pressed.connect(func():
   selected_id=id
   selected.emit(id)
   queue_redraw())
  add_child(button)
  buttons[id]=button
 resized.connect(layout,CONNECT_ONE_SHOT)
 layout()
func center_of(node: Dictionary) -> Vector2:
 return Vector2(100+float(node.position[0])*(size.x-200),40+float(node.position[1])*(size.y-80))
func layout():
 for node in nodes: buttons[node.id].position=center_of(node)-Vector2(81,31)
 queue_redraw()
func _draw():
 for i in range(42): draw_circle(Vector2(fmod(i*117.3,size.x),fmod(i*73.8,size.y)),1.2,Color(0.75,0.8,0.9,0.3))
 for node in nodes:
  var center=center_of(node)
  var requirements: Array=node.get("prerequisites",node.get("requires",[])) if not family.is_empty() else node.requires
  for prerequisite in requirements:
   var source: Dictionary={}
   for candidate in nodes:
    if candidate.id==prerequisite: source=candidate
   if not source.is_empty(): draw_line(center,center_of(source),tint if learned.has(node.id) else Color("42536a"),2,true)
  if node.id==selected_id: draw_arc(center,53,0,TAU,48,Color("f8df9c"),3,true)

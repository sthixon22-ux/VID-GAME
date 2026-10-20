class_name SkillGraph
extends Control
signal selected(id: String)
var class_name_="Paladin"
var nodes: Array=[]
var buttons: Dictionary={}
var selected_id="oath"
func configure(class_: String):
 class_name_=class_
 nodes=State.classes[class_].nodes
 for c in get_children(): c.queue_free()
 buttons.clear()
 for node in nodes:
  var id: String=node.id
  var button=Button.new()
  button.custom_minimum_size=Vector2(162,62)
  button.text=node.name+"\n"+("LEARNED" if State.hero.skills[class_].has(id) else "%s SP" % int(node.cost))
  button.tooltip_text=node.description
  var style=StyleBoxFlat.new()
  style.bg_color=Color("544a32") if State.hero.skills[class_].has(id) else Color("1d3048")
  style.border_color=Color(State.classes[class_].color)
  style.set_border_width_all(2)
  style.set_corner_radius_all(8)
  button.add_theme_stylebox_override("normal",style)
  button.add_theme_font_size_override("font_size",16)
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
 for node in nodes:
  var button: Button=buttons[node.id]
  button.position=center_of(node)-Vector2(81,31)
 queue_redraw()
func _draw():
 var color_=Color(State.classes[class_name_].color)
 for i in range(42):
  var point=Vector2(fmod(i*117.3,size.x),fmod(i*73.8,size.y))
  draw_circle(point,1.2,Color(0.75,0.8,0.9,0.3))
 for node in nodes:
  var center=center_of(node)
  var learned=State.hero.skills[class_name_].has(node.id)
  for requirement in node.requires:
   var source=State.skill_node(class_name_,requirement)
   draw_line(center,center_of(source),color_ if learned else Color("42536a"),3,true)
  draw_circle(center,46,color_.darkened(0.7) if learned else Color("172638"))
  draw_arc(center,47,0,TAU,48,color_ if learned else Color("637184"),2,true)
  if node.id==selected_id: draw_arc(center,53,0,TAU,48,Color("f8df9c"),3,true)

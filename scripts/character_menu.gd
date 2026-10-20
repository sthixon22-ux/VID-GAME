extends Node
var page="equipment"
var selected_class="Paladin"
var slot="Weapon"
var selected_skill="oath"
var body: Control
var preview: SubViewport
var preview_root: Node3D
var preview_actor: Node3D
var graph: SkillGraph
var info: VBoxContainer
var point_label: Label
var header_title: Label
var time_=0.0
var model_yaw=PI+0.35
func _ready():
 selected_class=State.hero.primary
 var layer=CanvasLayer.new()
 add_child(layer)
 var backdrop=ColorRect.new()
 backdrop.color=Color("0d1627")
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layer.add_child(backdrop)
 var header=UI.panel(self,Vector2(20,16),Vector2(1240,100))
 header_title=UI.label(header,"")
 header_title.add_theme_font_size_override("font_size",25)
 var tabs=HBoxContainer.new()
 header.add_child(tabs)
 UI.button(tabs,"Equipment & Appearance",func(): show_page("equipment"))
 UI.button(tabs,"Class Skill Trees",func(): show_page("skills"))
 UI.button(tabs,"Return to adventure  [Esc]",leave)
 body=Control.new()
 body.position=Vector2(0,125)
 body.size=Vector2(1280,590)
 layer.add_child(body)
 show_page(State.menu_page)
func clear_body():
 for child in body.get_children():
  body.remove_child(child)
  child.queue_free()
 preview_actor=null
 preview=null
 graph=null
func content_panel(pos: Vector2, size_: Vector2) -> VBoxContainer:
 # Reparent the generated panel out of its helper CanvasLayer into this page.
 var box=UI.panel(body,Vector2.ZERO,size_)
 var panel=box.get_parent().get_parent()
 var layer_=panel.get_parent()
 layer_.remove_child(panel)
 body.add_child(panel)
 panel.position=pos
 layer_.queue_free()
 return box
func show_page(which: String):
 page=which
 header_title.text="CHARACTER  /  %s · LEVEL %s" % [State.hero.primary,State.hero.level]
 clear_body()
 if which=="skills": build_skills()
 else: build_equipment()
func build_equipment():
 var slots=content_panel(Vector2(20,0),Vector2(310,570))
 UI.label(slots,"EQUIPPED GEAR").add_theme_font_size_override("font_size",22)
 for key in State.hero.equipment:
  var selected: String=key
  UI.button(slots,"%s\n%s" % [key,State.hero.equipment[key]],func():
   slot=selected
   show_page("equipment"))
 var viewport_container=SubViewportContainer.new()
 viewport_container.position=Vector2(345,0)
 viewport_container.size=Vector2(450,450)
 viewport_container.stretch=true
 body.add_child(viewport_container)
 preview=SubViewport.new()
 preview.size=Vector2i(450,450)
 preview.own_world_3d=true
 viewport_container.add_child(preview)
 preview_root=Node3D.new()
 preview.add_child(preview_root)
 Art.environment_(preview_root)
 preview_actor=Art.actor("Hero",State.hero.equipment)
 preview_root.add_child(preview_actor)
 preview_actor.rotation.y=model_yaw
 var camera=Camera3D.new()
 preview_root.add_child(camera)
 camera.position=Vector3(0,1.3,3.2)
 camera.look_at(Vector3(0,1.05,0))
 camera.current=true
 var stats=content_panel(Vector2(345,450),Vector2(450,120))
 var attributes=State.stats()
 UI.label(stats,"ATK %s   DEF %s   SPD %s\nMAX HP %s   MAX MP %s" % [attributes.attack,attributes.defense,attributes.speed,attributes.max_hp,attributes.max_mp])
 var row=HBoxContainer.new()
 stats.add_child(row)
 UI.button(row,"Rotate left",func(): model_yaw-=0.55)
 UI.button(row,"Rotate right",func(): model_yaw+=0.55)
 var options=content_panel(Vector2(810,0),Vector2(450,570))
 UI.label(options,"CHOOSE %s" % slot.to_upper()).add_theme_font_size_override("font_size",22)
 UI.label(options,"Demo wardrobe · gear is free to try")
 var items: Array=[]
 for item in State.equipment_data:
  if State.equipment_data[item].slot==slot: items.append(item)
 if slot!="Weapon": items.append("None")
 for item in items:
  var name_: String=item
  var data: Dictionary=State.equipment_data.get(item,{"attack":0,"defense":0})
  var old: Dictionary=State.equipment_data.get(State.hero.equipment[slot],{"attack":0,"defense":0})
  var button=UI.button(options,"%s%s\nATK %+d  DEF %+d" % ["✓ " if State.hero.equipment[slot]==item else "",item,int(data.attack)-int(old.attack),int(data.defense)-int(old.defense)],func():
   State.equip(slot,name_)
   Sound.cue("confirm")
   show_page("equipment"))
  button.tooltip_text="Change visible gear and derived stats."
func build_skills():
 var heading=content_panel(Vector2(20,0),Vector2(1240,82))
 var tabs=HBoxContainer.new()
 heading.add_child(tabs)
 for class_ in State.classes:
  var selected: String=class_
  UI.button(tabs,"%s%s" % [class_," · PRIMARY" if State.hero.primary==class_ else ""],func():
   selected_class=selected
   selected_skill="oath"
   show_page("skills"))
 point_label=UI.label(heading,"Available skill points: %s · Select a node to see its effect and prerequisites." % State.hero.points)
 graph=SkillGraph.new()
 graph.position=Vector2(25,90)
 graph.size=Vector2(845,470)
 body.add_child(graph)
 graph.configure(selected_class)
 graph.selected_id=selected_skill
 graph.selected.connect(func(id):
  selected_skill=id
  refresh_skill_info())
 info=content_panel(Vector2(895,90),Vector2(365,470))
 refresh_skill_info()
func refresh_skill_info():
 for child in info.get_children():
  info.remove_child(child)
  child.queue_free()
 var node=State.skill_node(selected_class,selected_skill)
 UI.label(info,selected_class.to_upper()+" / "+node.name).add_theme_font_size_override("font_size",21)
 var description=UI.label(info,node.description)
 description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 description.custom_minimum_size=Vector2(300,75)
 var learned=State.hero.skills[selected_class].has(node.id)
 var missing: Array=[]
 for requirement in node.requires:
  if not State.hero.skills[selected_class].has(requirement): missing.append(State.skill_node(selected_class,requirement).name)
 var state="LEARNED" if learned else ("Requires: "+", ".join(missing) if not missing.is_empty() else "Available to learn")
 UI.label(info,"%s\nCost: %s skill points\nPoints available: %s" % [state,int(node.cost),State.hero.points])
 if node.id=="mythic":
  var label=UI.label(info,"AVAILABLE IN COMBAT" if learned and State.hero.primary==selected_class else "Only usable while this class is PRIMARY.\nUnlock stays saved when switching classes.")
  label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var learn=UI.button(info,"Learn skill" if not learned else "Already learned",func():
  State.invest_skill(selected_class,selected_skill)
  Sound.cue("confirm")
  show_page("skills"))
 learn.disabled=learned or not missing.is_empty() or State.hero.points<int(node.cost)
 UI.button(info,"Make %s primary" % selected_class,func():
  State.set_primary(selected_class)
  show_page("skills"))
 UI.label(info,"Starting abilities remain available.\nGold nodes are learned.\nLines show the required path.")
func _process(delta):
 time_+=delta
 if is_instance_valid(preview_actor):
  preview_actor.rotation.y=lerp_angle(preview_actor.rotation.y,model_yaw,minf(1,delta*8))
  Art.animate(preview_actor,time_,false)
func _unhandled_input(event):
 if event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE,KEY_I]: leave()
func leave():
 State.save_game()
 get_tree().change_scene_to_file(State.travel_scene())

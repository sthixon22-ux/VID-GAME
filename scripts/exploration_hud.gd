class_name ExplorationHUD
extends CanvasLayer
var status:Label
var objective:Label
var prompt:Label
var notification:Label
var map:TrailMap
var elapsed=0.0
var last_notice=""
func _ready():
 layer=2
 var root=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(root)
 var backing=ColorRect.new()
 backing.position=Vector2(20,636)
 backing.size=Vector2(970,66)
 backing.color=Color(0.025,0.04,0.055,0.76)
 backing.mouse_filter=Control.MOUSE_FILTER_IGNORE
 root.add_child(backing)
 status=make_label(root,Vector2(34,641),Vector2(950,26),18)
 objective=make_label(root,Vector2(34,670),Vector2(930,22),14)
 prompt=make_label(root,Vector2(240,595),Vector2(800,30),18)
 prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 notification=make_label(root,Vector2(260,38),Vector2(760,50),22)
 notification.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 map=TrailMap.new()
 map.position=Vector2(1050,510)
 map.size=Vector2(210,190)
 root.add_child(map)
func make_label(root:Node,pos:Vector2,size_:Vector2,font_size:int)->Label:
 var label=Label.new()
 label.position=pos
 label.size=size_
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color("f4e9d2"))
 label.add_theme_color_override("font_shadow_color",Color.BLACK)
 label.add_theme_constant_override("shadow_offset_x",1)
 label.add_theme_constant_override("shadow_offset_y",2)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 root.add_child(label)
 return label
func update_view(hero_pos:Vector3,goal:String,context:String,notice:String,delta:float):
 var stats=State.stats()
 status.text="%s · Lv %s     HP %s / %s     MP %s / %s     %s gold     [Esc] Menu · [Tab] Inventory" % [State.hero.profile.name,State.hero.level,State.hero.hp,stats.max_hp,State.hero.mp,stats.max_mp,State.hero.gold]
 objective.text=goal+"   ·   [J] Journal"
 prompt.text=context
 if notice!=last_notice:
  last_notice=notice
  notification.text=notice
  elapsed=4.0
 elapsed=maxf(0,elapsed-delta)
 notification.modulate.a=clampf(elapsed,0,1)
 map.hero_position=hero_pos
 map.queue_redraw()

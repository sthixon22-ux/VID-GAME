class_name UI
extends RefCounted
static func panel(parent: Node, position: Vector2, size: Vector2) -> VBoxContainer:
 var layer=CanvasLayer.new()
 parent.add_child(layer)
 var panel_=PanelContainer.new()
 layer.add_child(panel_)
 var theme_=Theme.new()
 theme_.default_font_size=17
 var frame=StyleBoxFlat.new()
 frame.bg_color=Color(0.055,0.095,0.15,0.94)
 frame.border_color=Color("b6a272")
 frame.set_border_width_all(2)
 frame.set_corner_radius_all(10)
 frame.content_margin_left=14
 frame.content_margin_right=14
 frame.content_margin_top=10
 frame.content_margin_bottom=10
 theme_.set_stylebox("panel","PanelContainer",frame)
 for style in ["normal","hover","pressed","focus"]:
  var button_style=StyleBoxFlat.new()
  button_style.bg_color=Color("35516c") if style=="hover" else Color("1c3046")
  button_style.set_corner_radius_all(5)
  button_style.content_margin_top=7
  button_style.content_margin_bottom=7
  button_style.content_margin_left=12
  theme_.set_stylebox(style,"Button",button_style)
 theme_.set_color("font_color","Label",Color("f5e8cc"))
 panel_.theme=theme_
 panel_.position=position
 panel_.size=size
 var scroll=ScrollContainer.new()
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
 panel_.add_child(scroll)
 var v=VBoxContainer.new()
 v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(v)
 return v
static func label(parent: Node, text_: String) -> Label:
 var l=Label.new()
 l.text=text_
 if parent is VBoxContainer:
  l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(l)
 return l
static func button(parent: Node, text_: String, action: Callable) -> Button:
 var b=Button.new()
 b.text=text_
 if parent is VBoxContainer: b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 parent.add_child(b)
 b.pressed.connect(action)
 return b

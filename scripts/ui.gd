class_name UI
extends RefCounted
static func panel(parent: Node, position: Vector2, size: Vector2) -> VBoxContainer:
 var layer=CanvasLayer.new()
 parent.add_child(layer)
 var panel_=PanelContainer.new()
 layer.add_child(panel_)
 panel_.position=position
 panel_.size=size
 var scroll=ScrollContainer.new()
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 panel_.add_child(scroll)
 var v=VBoxContainer.new()
 v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(v)
 return v
static func label(parent: Node, text_: String) -> Label:
 var l=Label.new()
 l.text=text_
 parent.add_child(l)
 return l
static func button(parent: Node, text_: String, action: Callable) -> Button:
 var b=Button.new()
 b.text=text_
 parent.add_child(b)
 b.pressed.connect(action)
 return b

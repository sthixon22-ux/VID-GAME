class_name OptionsPanel
extends CanvasLayer
var active=false
var shade: ColorRect
var panel: PanelContainer
var content: VBoxContainer
var speed_control: OptionButton
func _ready():
 layer=50
 shade=ColorRect.new()
 shade.color=Color(0.01,0.025,0.05,0.82)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 content=UI.panel(self,Vector2(320,70),Vector2(640,590))
 panel=content.get_parent().get_parent()
 panel.get_parent().layer=51
 UI.label(content,"SETTINGS").add_theme_font_size_override("font_size",28)
 UI.label(content,"Presentation changes do not alter combat rules.")
 var speed_row=HBoxContainer.new()
 content.add_child(speed_row)
 UI.label(speed_row,"Battle animations: ")
 var speed=OptionButton.new()
 speed_control=speed
 for label in ["Normal · 1×","Fast · 1.75×","Very fast · 2.5×"]: speed.add_item(label)
 var values=[1.0,1.75,2.5]
 speed.select(0 if UserSettings.battle_speed<1.5 else (1 if UserSettings.battle_speed<2.2 else 2))
 speed.item_selected.connect(func(index): UserSettings.set_option("battle_speed",values[index]))
 speed_row.add_child(speed)
 checkbox("Minimal battle animations","minimal_animations",UserSettings.minimal_animations)
 checkbox("Reduced battle camera movement","reduced_camera_motion",UserSettings.reduced_camera_motion)
 checkbox("Mute music and sound","muted",UserSettings.muted)
 slider("Music volume","music_db",-40,-6,UserSettings.music_db,"dB")
 slider("Sound effect volume","effects_db",-40,-6,UserSettings.effects_db,"dB")
 slider("Mouse camera sensitivity","camera_sensitivity",0.25,2,UserSettings.camera_sensitivity,"×")
 UI.label(content,"WASD move · Shift sprint · Right mouse orbit\nE interact · I equipment · K skills · Esc close/menu\nSettings are saved separately from your adventure.")
 UI.button(content,"Close settings  [Esc]",close)
 close()
func checkbox(text_: String, key: String, value: bool):
 var box=CheckButton.new()
 box.text=text_
 box.button_pressed=value
 box.toggled.connect(func(enabled): UserSettings.set_option(key,enabled))
 content.add_child(box)
func slider(label: String, key: String, low: float, high: float, value: float, suffix: String):
 var text=UI.label(content,"%s: %.2f %s" % [label,value,suffix])
 var control=HSlider.new()
 control.min_value=low
 control.max_value=high
 control.step=0.05 if suffix=="×" else 1.0
 control.value=value
 control.custom_minimum_size=Vector2(0,22)
 control.value_changed.connect(func(number):
  text.text="%s: %.2f %s" % [label,number,suffix]
  UserSettings.set_option(key,number))
 content.add_child(control)
func open():
 active=true
 shade.show()
 panel.show()
 speed_control.grab_focus()
func close():
 active=false
 if is_instance_valid(shade): shade.hide()
 if is_instance_valid(panel): panel.hide()
func _input(event):
 if not active: return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  get_viewport().set_input_as_handled()
  close()

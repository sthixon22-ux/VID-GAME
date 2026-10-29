class_name Dialogue
extends CanvasLayer
signal closed
var active=false
var lines: Array=[]
var index=0
var callback: Callable
var panel: PanelContainer
var portrait: TextureRect
var face_view:DialoguePortrait
var speaker: Label
var words: Label
var next: Button
var database: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
func _ready():
 layer=20
 var content=UI.panel(self,Vector2(100,430),Vector2(1080,260))
 # UI.panel owns an inner CanvasLayer; give it dialogue priority as well.
 content.get_parent().get_parent().get_parent().layer=20
 panel=content.get_parent().get_parent()
 var row=HBoxContainer.new()
 row.add_theme_constant_override("separation",22)
 content.add_child(row)
 face_view=DialoguePortrait.new();add_child(face_view)
 portrait=TextureRect.new()
 portrait.custom_minimum_size=Vector2(175,175)
 portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 row.add_child(portrait)
 var text=VBoxContainer.new()
 text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_child(text)
 speaker=UI.label(text,"")
 speaker.add_theme_font_size_override("font_size",24)
 words=UI.label(text,"")
 words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 words.custom_minimum_size=Vector2(780,110)
 words.add_theme_font_size_override("font_size",21)
 next=UI.button(text,"Continue  [E / Space]",advance)
 panel.hide()
func show_id(id: String, on_finished: Callable=Callable()):
 lines=database.get(id,[])
 if lines.is_empty(): return
 callback=on_finished
 index=0
 active=true
 panel.show()
 render_line()
func render_line():
 speaker.text=str(State.hero.profile.get("name","Hero")) if str(lines[index][0])=="Hero" else str(lines[index][0])
 words.text=str(lines[index][1])
 face_view.show_speaker(str(lines[index][0]))
 portrait.texture=face_view.get_texture()
 next.text="Continue  [E / Space]" if index<lines.size()-1 else "Close  [E / Space]"
func advance():
 if not active: return
 Sound.cue("confirm")
 index+=1
 if index<lines.size(): render_line()
 else:
  active=false
  panel.hide()
  face_view.render_target_update_mode=SubViewport.UPDATE_DISABLED
  face_view.identity=""
  closed.emit()
  if callback.is_valid(): callback.call()
func _input(event):
 if active and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_E,KEY_SPACE,KEY_ENTER]:
  # Advancing may change scenes and detach this node from its viewport.
  get_viewport().set_input_as_handled()
  advance()

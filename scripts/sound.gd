extends Node
var music: AudioStreamPlayer
var muted=false
var current=""
func _ready():
 get_tree().auto_accept_quit=false
 music=AudioStreamPlayer.new()
 add_child(music)
 music.volume_db=-20
 var config=ConfigFile.new()
 if config.load("user://settings.cfg")==OK: muted=config.get_value("audio","muted",false)
 music.finished.connect(func():
  if not muted: music.play())
func theme_(name_: String):
 if DisplayServer.get_name()=="headless": return
 if name_==current: return
 current=name_
 music.stream=load("res://assets/audio/%s.wav" % name_)
 if not muted: music.play()
func cue(name_: String):
 if DisplayServer.get_name()=="headless": return
 if muted: return
 var player=AudioStreamPlayer.new()
 add_child(player)
 player.volume_db=-15
 player.stream=load("res://assets/audio/%s.wav" % name_)
 player.finished.connect(player.queue_free)
 player.play()
func toggle():
 muted=not muted
 if muted: music.stop()
 elif music.stream: music.play()
 var config=ConfigFile.new()
 config.set_value("audio","muted",muted)
 config.save("user://settings.cfg")
func _exit_tree():
 for child in get_children():
  if child is AudioStreamPlayer:
   child.stop()
   child.stream=null

func stop_all():
 for child in get_children():
  if child is AudioStreamPlayer:
   child.stop()
   child.stream=null
 await get_tree().create_timer(0.15).timeout
func _notification(what):
 if what==NOTIFICATION_WM_CLOSE_REQUEST:
  await stop_all()
  get_tree().quit()

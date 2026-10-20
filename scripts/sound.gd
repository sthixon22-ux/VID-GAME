extends Node
var music: AudioStreamPlayer
var muted: bool:
 get: return UserSettings.muted
var current=""
func _ready():
 get_tree().auto_accept_quit=false
 music=AudioStreamPlayer.new()
 add_child(music)
 music.volume_db=-20
 UserSettings.changed.connect(apply_settings)
 apply_settings()
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
 player.volume_db=UserSettings.effects_db
 player.stream=load("res://assets/audio/%s.wav" % name_)
 player.finished.connect(player.queue_free)
 player.play()
func toggle():
 UserSettings.set_option("muted",not muted)
func apply_settings():
 if not is_instance_valid(music): return
 music.volume_db=UserSettings.music_db
 if muted:
  music.stop()
  for child in get_children():
   if child is AudioStreamPlayer:
    child.stop()
    if child!=music: child.queue_free()
 elif music.stream and not music.playing: music.play()
 for child in get_children():
  if child is AudioStreamPlayer and child!=music: child.volume_db=UserSettings.effects_db
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

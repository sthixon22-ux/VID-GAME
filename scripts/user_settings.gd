extends Node
signal changed
const PATH="user://settings.cfg"
var config=ConfigFile.new()
var muted=false
var music_db=-20.0
var effects_db=-15.0
var battle_speed=1.0
var minimal_animations=false
var reduced_camera_motion=false
var camera_sensitivity=1.0
func _ready():
 reload()
func reload():
 config=ConfigFile.new()
 config.load(PATH)
 muted=bool(config.get_value("audio","muted",false))
 music_db=clampf(float(config.get_value("audio","music_db",-20.0)),-40,-6)
 effects_db=clampf(float(config.get_value("audio","effects_db",-15.0)),-40,-6)
 battle_speed=clampf(float(config.get_value("presentation","battle_speed",1.0)),1,2.5)
 minimal_animations=bool(config.get_value("presentation","minimal_animations",false))
 reduced_camera_motion=bool(config.get_value("presentation","reduced_camera_motion",false))
 camera_sensitivity=clampf(float(config.get_value("controls","camera_sensitivity",1.0)),0.25,2)
 changed.emit()
func set_option(key: String, value):
 match key:
  "muted": muted=bool(value)
  "music_db": music_db=clampf(float(value),-40,-6)
  "effects_db": effects_db=clampf(float(value),-40,-6)
  "battle_speed": battle_speed=clampf(float(value),1,2.5)
  "minimal_animations": minimal_animations=bool(value)
  "reduced_camera_motion": reduced_camera_motion=bool(value)
  "camera_sensitivity": camera_sensitivity=clampf(float(value),0.25,2)
  _: return
 config.set_value("audio","muted",muted)
 config.set_value("audio","music_db",music_db)
 config.set_value("audio","effects_db",effects_db)
 config.set_value("presentation","battle_speed",battle_speed)
 config.set_value("presentation","minimal_animations",minimal_animations)
 config.set_value("presentation","reduced_camera_motion",reduced_camera_motion)
 config.set_value("controls","camera_sensitivity",camera_sensitivity)
 config.save(PATH)
 changed.emit()
# Presentation clocks only. Never change Engine.time_scale or the combat simulator.
func duration(seconds: float) -> float:
 return seconds/battle_speed
func tween(host: Node) -> Tween:
 return host.create_tween().set_speed_scale(battle_speed)

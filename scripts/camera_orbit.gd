class_name CameraOrbit
extends RefCounted
# Keyboard alternative to RMB drag. Call only when exploration is not modal.
static func step(yaw:float,pitch:float,delta:float)->Vector2:
 var horizontal=float(Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_LEFT))
 var vertical=float(Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_UP))
 return Vector2(yaw+horizontal*delta*1.7*UserSettings.camera_sensitivity,clampf(pitch+vertical*delta*.9*UserSettings.camera_sensitivity,-1.1,-.15))

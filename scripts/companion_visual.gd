class_name CompanionVisual
extends RefCounted
static func build(id: String) -> Node3D:
 return model("res://assets/models/companions/%s.glb" % id)
static func model(path:String)->Node3D:
 var source:Node3D=load(path).instantiate()
 var actor=Node3D.new()
 var body=source.find_child("Body",true,false)
 body.owner=null
 body.get_parent().remove_child(body)
 actor.add_child(body)
 source.free()
 return actor

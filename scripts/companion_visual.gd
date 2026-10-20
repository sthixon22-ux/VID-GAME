class_name CompanionVisual
extends RefCounted
static func build(id: String) -> Node3D:
 if id=="intro_wolf": return Art.actor("Wolf")
 var data: Dictionary=State.companions[id]
 var color=Color(data.color)
 if id in ["dire_wolf","spirit_fox","dragon","griffin"]:
  var actor=Art.actor("Wolf")
  for mesh in actor.find_children("*","MeshInstance3D",true,false):
   var material=mesh.material_override.duplicate()
   material.albedo_color=material.albedo_color.lerp(color,0.65)
   mesh.material_override=material
  var body=actor.get_node("Body")
  if id=="dire_wolf":
   actor.scale=Vector3.ONE*1.15
   for side in [-1,1]: Art.shape(body,Vector3(side*0.2,0.75,-0.95),Vector3(0.07,0.18,0.07),Color.IVORY,"cone")
  elif id=="spirit_fox":
   actor.scale=Vector3.ONE*0.85
   for i in range(3):
    var tail=Art.shape(body,Vector3((i-1)*0.3,0.95,0.9),Vector3(0.35,0.45,1.3),color.lightened(0.15))
    tail.rotation.y=(i-1)*0.45
   Art.shape(body,Vector3(0,1.45,-0.6),Vector3.ONE*0.12,Color("c5f4eb"))
  else:
   for side in [-1,1]:
    var wing=Art.shape(body,Vector3(side*0.85,1.1,0.1),Vector3(1.5,0.12,1.0),color.lightened(0.2),"cone")
    wing.rotation.z=side*0.3
    wing.name="Wing_"+str(side)
   if id=="griffin":
    Art.shape(body,Vector3(0,1,-1),Vector3(0.3,0.28,0.55),Color("e2b95f"),"cone").rotation.x=-PI/2
   else:
    for i in range(5): Art.shape(body,Vector3(0,1.03,i*0.28-0.3),Vector3(0.2,0.4,0.2),Color("e9d38d"),"cone")
  return actor
 var actor=Node3D.new()
 var body=Node3D.new()
 body.name="Body"
 actor.add_child(body)
 if id=="warhorse":
  Art.shape(body,Vector3(0,1,0),Vector3(0.8,0.9,1.6),color)
  Art.shape(body,Vector3(0,1.7,-0.65),Vector3(0.48,1.1,0.5),color)
  Art.shape(body,Vector3(0,2,-0.95),Vector3(0.48,0.6,0.8),color)
  Art.box(body,Vector3(0,1.45,0.15),Vector3(0.8,0.14,0.65),Color("466c80"))
  for side in [-1,1]:
   Art.shape(body,Vector3(side*0.17,2.4,-0.8),Vector3(0.14,0.4,0.15),color,"cone")
   for z in [-0.5,0.5]: Art.shape(body,Vector3(side*0.28,0.5,z),Vector3(0.2,1,0.2),color,"cylinder").name="Leg_%s_%s" % [side,z]
  Art.shape(body,Vector3(0,1.05,0.95),Vector3(0.25,0.7,0.35),Color("493a35"))
 else:
  Art.box(body,Vector3(0,1,0),Vector3(1.05,1.2,0.65),color)
  Art.box(body,Vector3(0,1.9,0),Vector3(0.7,0.7,0.6),color.lightened(0.1))
  for side in [-1,1]:
   Art.box(body,Vector3(side*0.75,1.1,0),Vector3(0.38,0.9,0.45),color).name="Arm_"+str(side)
   Art.box(body,Vector3(side*0.3,0.3,0),Vector3(0.4,0.6,0.5),color.darkened(0.15)).name="Leg_"+str(side)
   Art.box(body,Vector3(side*0.15,2,-0.32),Vector3(0.11,0.1,0.04),Color("a7e9d2"))
  Art.shape(body,Vector3(0,1.2,-0.36),Vector3(0.24,0.5,0.1),Color("95d7bf"),"cone")
 return actor

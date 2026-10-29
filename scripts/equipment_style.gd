class_name EquipmentStyle
extends RefCounted
# Cosmetic variants leave the authored grip origin and skeleton untouched.
static func decorate(root:Node3D,entry:Dictionary):
 var theme=str(entry.get("theme",""))
 if theme.is_empty():return
 root.set_meta("equipment_theme",theme)
 var tint=Color(entry.get("color","a8b6be"))
 for mesh in root.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh:continue
  for i in mesh.mesh.get_surface_count():
   var source=mesh.get_active_material(i)
   if not source is StandardMaterial3D:continue
   var mat:StandardMaterial3D=source.duplicate()
   mat.albedo_color=mat.albedo_color.lerp(tint,.45)
   mat.metallic=.65 if theme in ["steel","storm","sun"] else .25
   mat.roughness=.35 if theme in ["moon","star","rune"] else .55
   mesh.set_surface_override_material(i,mat)
 var motif=Node3D.new();motif.name="Theme_"+theme;root.add_child(motif)
 var family=str(entry.get("weapon_type",""))
 var center=Vector3(0,.62,0) if family!="bow" else Vector3(.04,.5,0)
 match theme:
  "bone":
   for side in [-1,1]:
    for i in 4:
     var spur=Art.shape(motif,Vector3(side*.13,.35+i*.2,0),Vector3(.13,.22,.13),tint,"cone");spur.rotation.z=side*.8
  "fire":
   for i in 4:
    var tongue=Art.shape(motif,Vector3(0,.45+i*.18,0),Vector3(.12,.3,.11),tint,"cone")
    tongue.rotation.z=sin(i*2)*.45;tongue.material_override=BattleMotion.effect_material(tint,.8)
  "storm":
   for i in 5:
    var spark=Art.box(motif,Vector3(sin(i*PI/2)*.09,.3+i*.16,-.04),Vector3(.035,.19,.035),tint)
    spark.rotation.z=.55 if i%2==0 else -.55;spark.material_override=BattleMotion.effect_material(tint)
  "nature":
   for i in 4:
    var leaf=Art.shape(motif,Vector3(sin(i*2)*.12,.3+i*.2,0),Vector3(.11,.23,.035),tint);leaf.rotation.z=sin(i*2)*.6
  "shadow":
   for side in [-1,1]:
    var fang=Art.shape(motif,Vector3(side*.13,.3,0),Vector3(.12,.4,.08),tint,"cone");fang.rotation.z=side*.5
  _:
   var gem=Art.shape(motif,center,Vector3(.16,.27,.13),tint,"cone")
   gem.material_override=BattleMotion.effect_material(tint,.85)
   for side in [-1,1]:Art.shape(motif,center+Vector3(side*.15,0,0),Vector3(.08,.19,.08),tint,"cone")

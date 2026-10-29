class_name WardrobeVisual
extends RefCounted
const CHESTS={
 "Knight’s Harness":{"outfit":"ranger","color":"9aaebc","style":"plate"},
 "Runewoven Robe":{"outfit":"traveler","color":"6ca2b8","style":"robe"},
 "Shadowstalker Leathers":{"outfit":"ranger","color":"75638c","style":"leather"},
 "Wildheart Mantle":{"outfit":"ranger","color":"6f936a","style":"coat"},
 "Sunpriest Vestments":{"outfit":"traveler","color":"d0b76c","style":"robe"},
 "Wayfarer’s Wraps":{"outfit":"traveler","color":"a48770","style":"cloth"},
 "None":{"outfit":"traveler","color":"ffffff","style":"none"},
 "Traveler's Clothing":{"outfit":"traveler","color":"d5bc8e","style":"cloth"},
 "Leather Vest":{"outfit":"ranger","color":"bc8b5c","style":"leather"},
 "Steel Cuirass":{"outfit":"ranger","color":"b1bcc9","style":"plate"},
 "Verdant Robe":{"outfit":"traveler","color":"71a58d","style":"robe"},
 "Reedcoat":{"outfit":"ranger","color":"789aaa","style":"coat"},
 "Sluicekeeper Robe":{"outfit":"traveler","color":"92b8c9","style":"robe"}}
static func profile(chest:String)->Dictionary:
 var aliases={"Sunveil Coat":"Reedcoat","Forgeguard Coat":"Steel Cuirass"}
 var gear:Dictionary=State.equipment_data.get(chest,{})
 var result:Dictionary=CHESTS.get(gear.get("armor_profile",aliases.get(chest,chest)),CHESTS["None"]).duplicate()
 if gear.has("theme"):result.color=gear.color
 return result
static func apply(hero:HeroVisual,chest:String):
 var definition=profile(chest)
 hero.set_meta("wardrobe_style",definition.style)
 for mesh in hero.model.find_children("*","MeshInstance3D",true,false):
  if mesh.name.contains("Body") or mesh.name.contains("Legs") or mesh.name.contains("Pauldron"):
   for i in mesh.mesh.get_surface_count():
    var material=mesh.get_active_material(i)
    if material is StandardMaterial3D and material.resource_name in ["MI_Ranger","MI_Peasant"]:
     var variant:StandardMaterial3D=material.duplicate()
     variant.albedo_color*=Color(definition.color)
     variant.roughness=.8
     var gear=State.equipment_data.get(chest,{})
     if gear.has("theme"):
      var texture_path="res://assets/textures/equipment/%s_%s.webp" % [gear.id,hero.sex.to_lower()]
      if ResourceLoader.exists(texture_path):variant.albedo_texture=load(texture_path);variant.albedo_color=Color.WHITE
     if definition.style=="plate" and (mesh.name.contains("Body") or mesh.name.contains("Pauldron")):
      variant.albedo_texture=null
      variant.albedo_color=Color("7b91a2")
      variant.metallic=.78
      variant.roughness=.32
     mesh.set_surface_override_material(i,variant)
 if State.equipment_data.get(chest,{}).has("theme"):
  var themed=State.equipment_data[chest]
  hero.set_meta("armor_theme",themed.theme)
  var clasp=Node3D.new();clasp.name="ArmorMotif_"+str(themed.theme);hero.socket("Chest").add_child(clasp)
  clasp.position=Vector3(0,.03,.13);clasp.scale=Vector3.ONE*.18
  EquipmentStyle.decorate(clasp,{"theme":themed.theme,"color":themed.color})
 if definition.style=="plate":plate(hero)
 if definition.style in ["robe","coat"]:skirt(hero,Color(definition.color),definition.style=="robe")
static func plate(hero:HeroVisual):
 # Copy the authored, already-weighted torso surface. Preserve UVs, skin and rig paths.
 var torso=hero.model.find_child("*Ranger_Body",true,false) as MeshInstance3D
 if not torso:return
 var shell=torso.duplicate() as MeshInstance3D
 shell.name="EquippedChestSkinnedPlate"
 var mesh=ArrayMesh.new()
 for surface in torso.mesh.get_surface_count():
  var arrays=torso.mesh.surface_get_arrays(surface)
  var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
  for i in vertices.size():vertices[i]+=normals[i]*.012
  arrays[Mesh.ARRAY_VERTEX]=vertices
  mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 shell.mesh=mesh
 torso.get_parent().add_child(shell)
 shell.skin=torso.skin
 shell.skeleton=torso.skeleton
 var steel=StandardMaterial3D.new()
 steel.albedo_color=Color("93a9b8")
 steel.metallic=.8;steel.roughness=.3
 if State.equipment_data.get(hero.gear.get("Chest",""),{}).has("theme"):
  var path="res://assets/textures/equipment/%s_%s.webp" % [State.equipment_data[hero.gear.Chest].id,hero.sex.to_lower()]
  steel.albedo_color=Color(State.equipment_data[hero.gear.Chest].color)
  steel.albedo_texture=null
 shell.material_override=steel
static func skirt(hero:HeroVisual,color:Color,long:bool):
 # Original weighted garment extension; uses the same imported Skin/Skeleton.
 var torso=hero.model.find_child("*Body",true,false) as MeshInstance3D
 if not torso or not torso.skin:return
 var mesh=ArrayMesh.new()
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
 var vertices=PackedVector3Array();var normals=PackedVector3Array();var uvs=PackedVector2Array()
 var bones=PackedInt32Array();var weights=PackedFloat32Array();var indices=PackedInt32Array()
 # ArrayMesh bone indices refer to Skin binds, not Skeleton3D indices.
 var hip=-1
 for i in torso.skin.get_bind_count():
  if torso.skin.get_bind_name(i)=="Hips" or torso.skin.get_bind_bone(i)==hero.skeleton.find_bone("Hips"):hip=i;break
 if hip<0:hip=0
 var count=32
 for row in 3:
  var ratio=row/2.0
  var y=1.04-ratio*(.57 if long else .32)
  for i in count+1:
   var angle=i*TAU/count
   var ripple=sin(angle*8)*ratio*.009
   var rx=lerpf(.21,.33,ratio)+ripple
   var rz=lerpf(.145,.23,ratio)+ripple
   vertices.append(Vector3(cos(angle)*rx,y,sin(angle)*rz-.025))
   normals.append(Vector3(cos(angle),0,sin(angle)).normalized())
   uvs.append(Vector2(i/float(count),ratio))
   bones.append_array(PackedInt32Array([hip,0,0,0]));weights.append_array(PackedFloat32Array([1,0,0,0]))
 for row in 2:
  for i in count:
   var a=row*(count+1)+i
   indices.append_array(PackedInt32Array([a,a+1,a+count+1,a+1,a+count+2,a+count+1]))
 arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uvs
 arrays[Mesh.ARRAY_BONES]=bones;arrays[Mesh.ARRAY_WEIGHTS]=weights;arrays[Mesh.ARRAY_INDEX]=indices
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var garment=MeshInstance3D.new()
 garment.name="EquippedChestRobeSkirt" if long else "EquippedChestCoatTails"
 garment.mesh=mesh;garment.skin=torso.skin
 torso.get_parent().add_child(garment)
 garment.skeleton=torso.skeleton
 var material=StandardMaterial3D.new()
 material.albedo_color=color
 material.cull_mode=BaseMaterial3D.CULL_DISABLED
 material.roughness=.9
 material.albedo_texture=load("res://assets/textures/rpg/cloth_albedo.png")
 garment.material_override=material

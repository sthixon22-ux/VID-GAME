class_name ThematicEffects
extends RefCounted
static func show(host:Node3D,actor:Node3D,target:Node3D,label:String)->bool:
 var id=AbilityBook.id_for(label)
 var entry=AbilityBook.entry(id)
 if entry.is_empty() or entry.get("kind","")=="item" or id in ["attack","items","defend"]:return false
 if entry.effect in ["heal","buff","renewal","regrowth","meditate","weaken"]:return false
 var at=target.position+Vector3.UP
 var color_=Color(SkillEffects.COLORS.get(entry.get("damage_type","physical"),"e4bc89"))
 var effect=Node3D.new();effect.name="FX_"+id;host.add_child(effect);effect.set_meta("ability",id)
 match id:
  "dragon_slash":
   var spirit=CompanionVisual.build("dragon");effect.add_child(spirit);spirit.scale=Vector3.ONE*.6;spirit.position=actor.position+Vector3(0,.7,0)
   spirit.look_at(target.position+Vector3.UP)
   for mesh in spirit.find_children("*","MeshInstance3D",true,false):mesh.material_override=BattleMotion.effect_material(Color("f4bd7c"),.32)
   var swoop=UserSettings.tween(host);swoop.tween_property(spirit,"position",target.position+Vector3(0,1.3,-1),.65);swoop.tween_property(spirit,"scale",Vector3.ONE*.01,.25)
   for i in 16:BattleMotion.mote(effect,actor.position+Vector3(0,1+i*.025,0),at+Vector3(sin(i*.7),cos(i*.7)*.6,0),Color("f5a35b"),.5,.14)
   BattleMotion.arc(effect,at,Color("f9b36e"),true)
  "sacred_strike","dawn_avatar","paladin_master":
   var column=Art.shape(effect,target.position+Vector3(0,2,0),Vector3(.55,4,.55),Color("ffe7ab"),"cylinder")
   var energy=ShaderMaterial.new();energy.shader=load("res://assets/shaders/spell_energy.gdshader");column.material_override=energy
   for i in 3:BattleMotion.ring(effect,target.position+Vector3(0,.1+i*.7,0),Color("ffdc8f"),1.2-i*.2)
   for i in 18:BattleMotion.mote(effect,target.position+Vector3(sin(i)*.7,3.5,cos(i)*.7),at+Vector3(sin(i)*.3,-.8,cos(i)*.3),Color("fff1c6"),.65,.12)
  "barbarian_adept":
   for i in 4:
    var wave=BattleMotion.ring(effect,actor.position+Vector3(0,1.25,0),Color("e7b38e"),.5+i*.3)
    wave.rotation.x=PI/2
    var tween=UserSettings.tween(host);tween.tween_property(wave,"position",at,.5)
  "assassin_adept","nightfall":
   for i in 6:
    var angle=i*TAU/6
    var glyph=Art.box(effect,at+Vector3(sin(angle)*.6,cos(angle)*.6,0),Vector3(.05,.35,.04),Color("b78cda"));glyph.rotation.z=-angle;glyph.material_override=BattleMotion.effect_material(Color("b78cda"))
   var seal=BattleMotion.ring(effect,at,Color("ac76cd"),.85);seal.rotation.x=PI/2
  _:
   var element=str(entry.get("damage_type","physical"))
   if element=="lightning":
    for i in 9:
     var bolt=Art.box(effect,at+Vector3(sin(i*2)*.2,2.4-i*.3,0),Vector3(.07,.4,.07),color_);bolt.rotation.z=sin(i*2)*.75;bolt.material_override=BattleMotion.effect_material(color_)
   elif element=="ice":
    for i in 6:Art.shape(effect,at+Vector3(sin(i)*.5,-.4,cos(i)*.5),Vector3(.2,1.5,.2),color_,"cone").material_override=BattleMotion.effect_material(color_,.7)
   elif element=="nature" or entry.effect in ["root","regrowth","regeneration"]:BattleMotion.roots(effect,target.position,7)
   elif element in ["shadow","arcane","fire","holy","wind","sonic"]:
    for i in 14:
     var angle=i*TAU/14
     var start=actor.position+Vector3(sin(angle)*.25,1+cos(angle)*.25,0)
     var end=at+Vector3(sin(angle)*.7,cos(angle)*.7,cos(angle*2)*.35)
     BattleMotion.mote(effect,start,end,color_,.4+float(i%3)*.12,.1+float(i%2)*.04)
    var seal=BattleMotion.ring(effect,at,color_,.8);seal.rotation.x=PI/2
   else:
    var count=int(entry.get("hits",1))
    for i in count:
     BattleMotion.arc(effect,at+Vector3(0,i*.13,0),color_,true)
     if entry.has("sunder"):BattleMotion.ring(effect,target.position+Vector3(0,.1,0),Color("df926a"),1.2)
 var cleanup=UserSettings.tween(host);cleanup.tween_interval(1.15);cleanup.tween_callback(effect.queue_free)
 return id in ["dragon_slash","sacred_strike","dawn_avatar","paladin_master","barbarian_adept","assassin_adept","nightfall"]

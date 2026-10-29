class_name BattleMotion
extends RefCounted
# Each action combines a distinct skeleton clip with its own effect choreography.
const STYLES={
 "Attack":"thrust", "Sword Slash":"crescent", "Shield Bash":"shield_wave",
 "Sacred Strike":"holy_column", "Hunter's Mark":"target_sigil",
 "Thornbind":"root_spiral", "Regrowth":"petal_bloom",
 "Dawn Avatar":"solar_wings", "Wild Hunt":"spectral_pack",
 "Ancient Grove":"elder_grove", "Potion":"amber_motes",
 "Shield raised":"shield_stance", "Wolf bite":"wolf_pounce",
 "Wolf's encouragement":"wolf_song", "Wolf protects you":"wolf_guard",
 "Goblin club":"club_swing", "Briar lash":"briar_whip",
 "Crushing Canopy":"canopy_slam"
}
const COMPANION_COLORS={
 "Rending Fang":"d9be9b","Pack Howl":"accbd7","Moonfang Assault":"d7e6f2",
 "Gale Talons":"e8ddba","Skyward Grace":"d7e8ca","Tempest Dive":"c8e3e8",
 "Ember Breath":"ee9a63","Arcane Embers":"9ec8ef","Inferno Breath":"f4bc68",
 "Thunderhoof":"d5c19c","Wind of the Road":"b3d7c2","Dawn Charge":"f1dca1",
 "Spirit Spark":"becbff","Moonlit Renewal":"b9dce6","Sanctuary Bloom":"d1c4ed",
 "Stonefist":"b6c0aa","Granite Shelter":"89c6ae","Mountain Ward":"a2dbc0"}
static func effect_material(color_: Color, alpha: float=0.85) -> StandardMaterial3D:
 var material=StandardMaterial3D.new()
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_color=Color(color_,alpha)
 material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 material.emission_enabled=true
 material.emission=color_
 material.emission_energy_multiplier=1.2
 material.cull_mode=BaseMaterial3D.CULL_DISABLED
 return material
static func ring(host: Node3D, position_: Vector3, color_: Color, radius: float=1) -> MeshInstance3D:
 var mesh=MeshInstance3D.new()
 var torus=TorusMesh.new()
 torus.inner_radius=radius*0.92
 torus.outer_radius=radius
 torus.rings=24
 torus.ring_segments=8
 mesh.mesh=torus
 mesh.material_override=effect_material(color_)
 host.add_child(mesh)
 mesh.position=position_
 var tween=UserSettings.tween(host)
 tween.set_parallel(true)
 tween.tween_property(mesh,"scale",Vector3(1.6,1,1.6),0.65)
 tween.tween_property(mesh,"transparency",1.0,0.65)
 tween.chain().tween_callback(mesh.queue_free)
 return mesh
static func arc(host: Node3D, point: Vector3, color_: Color, wide: bool):
 var mesh=MeshInstance3D.new()
 var surface=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var radius=1.35 if wide else 0.65
 for i in range(22):
  var a=-1.4+i*2.8/22
  var b=-1.4+(i+1)*2.8/22
  var vertices=[Vector3(cos(a)*radius,sin(a)*radius,0),Vector3(cos(b)*radius,sin(b)*radius,0),Vector3(cos(a)*(radius-0.14),sin(a)*(radius-0.14),0),Vector3(cos(a)*(radius-0.14),sin(a)*(radius-0.14),0),Vector3(cos(b)*radius,sin(b)*radius,0),Vector3(cos(b)*(radius-0.14),sin(b)*(radius-0.14),0)]
  for vertex in vertices: surface.add_vertex(vertex)
 mesh.mesh=surface.commit()
 mesh.material_override=effect_material(color_)
 host.add_child(mesh)
 mesh.position=point
 mesh.rotation.z=-0.9
 var tween=UserSettings.tween(host)
 tween.set_parallel(true)
 tween.tween_property(mesh,"rotation:z",1.7,0.4)
 tween.tween_property(mesh,"transparency",1.0,0.45)
 tween.chain().tween_callback(mesh.queue_free)
static func mote(host: Node3D, start: Vector3, end: Vector3, color_: Color, time_: float=0.7, size_: float=0.09):
 var mesh=Art.shape(host,start,Vector3.ONE*size_,color_)
 mesh.material_override=effect_material(color_)
 var tween=UserSettings.tween(host)
 tween.set_parallel(true)
 tween.tween_property(mesh,"position",end,time_).set_trans(Tween.TRANS_SINE)
 tween.tween_property(mesh,"scale",Vector3.ONE*0.005,time_)
 tween.chain().tween_callback(mesh.queue_free)
static func roots(host: Node3D, point: Vector3, count: int=9):
 for i in range(count):
  var angle=i*TAU/count
  var pos=point+Vector3(sin(angle)*0.7,-0.4,cos(angle)*0.7)
  var thorn=Art.shape(host,pos,Vector3(0.19,1.1+i%3*0.25,0.19),Color("75ba79"),"cone")
  thorn.rotation=Vector3(cos(angle)*0.4,0,sin(angle)*0.4)
  var tween=UserSettings.tween(host)
  tween.tween_property(thorn,"position:y",0.7,0.25)
  tween.tween_interval(0.35)
  tween.tween_property(thorn,"scale",Vector3.ONE*0.01,0.3)
  tween.tween_callback(thorn.queue_free)
static func present(host: Node3D, actor: Node3D, target: Node3D, label: String) -> float:
 TravelRules.breadcrumb(str(State.hero.journey.region),"present "+label)
 label=label.trim_suffix(" · Critical!").trim_suffix(" · Effective!").trim_suffix(" · Resisted")
 if label.ends_with(" increased") or label.ends_with(" weakened"):
  var base=label.split(" · ")[0]
  if not AbilityBook.entry(base).is_empty():label=base
 var duration=0.95
 if actor.has_method("play_action") and (actor is CompanionActor or actor is MarshCreature or actor is FrontierCreature or STYLES.has(label) or not AbilityBook.entry(label).is_empty() or label in ["Victory","Defeat"]): duration=actor.play_action(label)
 elif not STYLES.has(label): duration=0.4
 var origin=actor.position
 var forward=(target.position-origin).normalized() if actor!=target else Vector3.ZERO
 var body=actor.get_node_or_null("Body")
 var companion_art=CompanionRules.ability_by_name(label)
 if actor!=target and ((not companion_art.is_empty() and companion_art.get("behavior","")=="Attack") or (actor is CompanionActor and label.ends_with(" · strike"))):
  var charge=UserSettings.tween(host)
  charge.tween_property(actor,"position",origin+forward*.85,.18)
  charge.tween_property(actor,"position",origin,.3)
 if (not actor is HeroVisual or actor.weapon_family not in ["bow","wand"]) and label in ["Attack","Sword Slash","Shield Bash","Sacred Strike","Dawn Avatar","Wild Hunt","Wolf bite","Goblin club","Briar lash"]:
  var lunge=UserSettings.tween(host)
  lunge.tween_property(actor,"position",origin+forward*(1.0 if label=="Wolf bite" else 0.6),duration*0.35)
  lunge.tween_property(actor,"position",origin,duration*0.6)
 if not actor.has_method("play_action") and body and label in ["Crushing Canopy","Wolf bite","Goblin club"]:
  var pose=UserSettings.tween(host)
  if label=="Crushing Canopy":
   pose.tween_property(body,"rotation:x",-0.45,0.35)
   pose.tween_property(body,"rotation:x",0.55,0.15)
   pose.tween_property(body,"rotation:x",0,0.4)
  elif label=="Wolf bite":
   pose.tween_property(body,"rotation:x",-0.25,0.15)
   pose.tween_property(body,"rotation:x",0.2,0.2)
   pose.tween_property(body,"rotation:x",0,0.25)
  elif label=="Goblin club":
   pose.tween_property(body,"rotation:y",-0.65,0.25)
   pose.tween_property(body,"rotation:y",0.4,0.15)
   pose.tween_property(body,"rotation:y",0,0.3)
 # Bow damage follows draw, release and flight; melee keeps its authored impact phase.
 var bow_shot=actor is HeroVisual and actor.weapon_family=="bow" and actor.weapon_action
 if bow_shot:actor.set_meta("shot_target_world",target.global_position+Vector3.UP*1.2)
 await host.get_tree().create_timer(UserSettings.duration(duration*(.82 if bow_shot else .38))).timeout
 var bespoke=ThematicEffects.show(host,actor,target,label)
 if bow_shot or bespoke:return duration
 var point=target.position
 match label:
  "Attack":
   if not actor is HeroVisual or actor.weapon_family!="bow":arc(host,point+Vector3.UP,Color("d7edff"),false)
  "Sword Slash": arc(host,point+Vector3.UP,Color("f5b181"),true)
  "Shield Bash":
   var wave=ring(host,point+Vector3.UP,Color("93d5f3"))
   wave.rotation.x=PI/2
  "Thunder Strike":
   arc(host,point+Vector3.UP,Color("b5d8ff"),true)
   for index in range(8):mote(host,point+Vector3(sin(index)*.4,3-index*.3,cos(index)*.25),point+Vector3(sin(index+1)*.3,2.5-index*.3,cos(index+1)*.3),Color("9dc7ff"),.25,.08)
  "Holy Light":
   ring(host,point+Vector3.UP*.1,Color("ffe6b1"),1.1)
   for index in range(8):mote(host,point+Vector3(sin(index)*.4,.3,cos(index)*.4),point+Vector3(0,2.4,0),Color("ffe7ad"),.6,.08)
  "Sacred Strike":
   arc(host,point+Vector3.UP,Color("ffdb80"),true)
   for i in range(9): mote(host,point+Vector3(sin(i)*0.3,3.5,cos(i)*0.3),point+Vector3(sin(i)*0.4,0.2,cos(i)*0.4),Color("ffe19c"),0.5,0.16)
   ring(host,point+Vector3.UP*0.1,Color("ffe5b0"))
  "Hunter's Mark":
   ring(host,point+Vector3.UP*0.08,Color("9edcba"),0.7)
   var mark=ring(host,point+Vector3.UP*2.2,Color("a7edce"),0.35)
   mark.rotation.x=PI/2
   for i in range(4): mote(host,actor.position+Vector3.UP,point+Vector3.UP*1.3,Color("a7edce"),0.3,0.14)
  "Thornbind": roots(host,point)
  "Regrowth", "Wolf's encouragement", "Potion":
   var color_=Color("ecba70") if label=="Potion" else (Color("9ac7ee") if label=="Wolf's encouragement" else Color("a0e0a3"))
   ring(host,point+Vector3.UP*0.08,color_)
   for i in range(16):
    var angle=i*TAU/16
    mote(host,point+Vector3(sin(angle)*0.8,0.2,cos(angle)*0.8),point+Vector3(sin(angle+1)*0.3,2.2,cos(angle+1)*0.3),color_,0.8,0.12)
  "Dawn Avatar":
   ring(host,actor.position+Vector3.UP*0.1,Color("ffdf90"),1.5)
   for side in [-1,1]:
    for i in range(8): mote(host,actor.position+Vector3(0,1.3,0),actor.position+Vector3(side*(0.5+i*0.18),1.8+sin(i*0.3),0.15),Color("ffdf90"),0.7,0.18)
   arc(host,point+Vector3.UP,Color("fff0b5"),true)
  "Wild Hunt":
   for i in range(3):
    var wolf=Art.actor("Wolf")
    host.add_child(wolf)
    if wolf.has_method("motion"):wolf.motion(true,true)
    wolf.position=actor.position+Vector3(0,0,i-1)
    for mesh in wolf.find_children("*","MeshInstance3D",true,false): mesh.material_override=effect_material(Color("a9e4d0"),0.6)
    wolf.look_at(target.position)
    var chase=UserSettings.tween(host)
    chase.tween_property(wolf,"position",point+forward*1.8+Vector3(0,0,i-1),0.6)
    chase.tween_callback(wolf.queue_free)
  "Ancient Grove":
   ring(host,point+Vector3.UP*0.07,Color("d7bde8"),2)
   for i in range(6):
    var angle=i*TAU/6
    var tree=Node3D.new()
    host.add_child(tree)
    tree.position=point+Vector3(sin(angle)*1.8,0,cos(angle)*1.8)
    Art.shape(tree,Vector3(0,0.8,0),Vector3(0.12,1.6,0.12),Color("d5b9dd"),"cylinder")
    Art.shape(tree,Vector3(0,1.5,0),Vector3(0.7,1.2,0.7),Color("b1d7bd"),"cone")
    var grow=UserSettings.tween(host)
    grow.tween_interval(0.6)
    grow.tween_property(tree,"scale",Vector3.ONE*0.01,0.4)
    grow.tween_callback(tree.queue_free)
  "Shield raised", "Wolf protects you": ring(host,actor.position+Vector3.UP*0.08,Color("9cc5e7"))
  "Oathbreaker Tide":
   ring(host,point+Vector3.UP*.1,Color("66d0d0"),2.5)
   for i in 16:mote(host,actor.position+Vector3.UP*2,point+Vector3(sin(i)*1.1,.5,cos(i)*1.1),Color("75cbd6"),.65,.2)
  "Crushing Canopy":
   ring(host,point+Vector3.UP*0.08,Color("c3a887"),1.4)
   roots(host,point,14)
  "Briar lash": roots(host,point,4)
  "Wolf bite": arc(host,point+Vector3.UP*0.8,Color("d9e1e5"),false)
  "Goblin club":
   for i in range(8): mote(host,point+Vector3.UP,point+Vector3(sin(i),1.5,cos(i)),Color("c9ad85"),0.45)
  _:
   var ability=AbilityBook.entry(label)
   if ability.is_empty():ability=companion_art
   if not ability.is_empty():
    var effect=ability.effect
    var healing=effect in ["heal","buff","renewal","regrowth","meditate","mana","ward","mana_item","elixir_item","ration_item"] or effect.begins_with("buff_")
    var color_=Color("a7e2ac") if healing else (Color("a3b5ee") if effect in ["magic","drain","frost"] else Color("e4bc89"))
    if effect=="buff":color_=Color({"attack":"e6a786","defense":"92bde7","agility":"92d9c4","dexterity":"e3d08d"}.get(ability.get("stat",""),"a7e2ac"))
    if effect=="drain": color_=Color("b69cce")
    if effect=="frost": color_=Color("a3ddeb")
    if ability.has("damage_type"):color_=Color(SkillEffects.COLORS.get(ability.damage_type,"e4bc89"))
    if COMPANION_COLORS.has(label):color_=Color(COMPANION_COLORS[label])
    ring(host,point+Vector3.UP*0.1,color_,1.1)
    for i in range(10): mote(host,point+Vector3(sin(i)*0.6,0.3,cos(i)*0.6) if healing else actor.position+Vector3.UP,point+Vector3(sin(i)*0.25,1.5,cos(i)*0.25),color_,0.5,0.12)
    if not healing: arc(host,point+Vector3.UP,color_,true)
   elif label.contains(" · ") and actor!=target:
    var color_=Color("e6b575") if label.contains("Ember") else (Color("b4e8ee") if label.contains("Wind") else Color("b8d8b0"))
    for i in range(6): mote(host,actor.position+Vector3.UP,point+Vector3(sin(i)*0.3,1.1,cos(i)*0.3),color_,0.3,0.13)
    arc(host,point+Vector3.UP,color_,false)
   elif label.begins_with("The crown fills"):
    ring(host,actor.position+Vector3.UP*.1,Color("56c9df"),1.7)
   elif label.begins_with("Branches coil"):
    ring(host,actor.position+Vector3.UP*0.1,Color("e8ae7c"),1.5)
 return duration

class_name FrontierCreature
extends Node3D
# Authored, already credited creature meshes carry the silhouette and animation.
# Encounter-specific ornaments are separate, removable visuals.
var kind="SandDrake"
var battle=false
var native:Node3D
var ornaments:Node3D
var clock=0.0
var orrery:Node3D
func _init(value:String="SandDrake"):kind=value
func _ready():
 var base={"SandDrake":"dragon","GlassSovereign":"dragon","Scarab":"bristleback","GlassWisp":"spirit_fox","CragHound":"dire_wolf","StormRoc":"griffin","ForgeSentinel":"golem","IronrootColossus":"golem"}.get(kind,"golem")
 native=CompanionActor.new("drake") if kind=="SandDrake" else CompanionVisual.build(base)
 add_child(native)
 var big=kind in ["GlassSovereign","IronrootColossus"]
 native.scale=Vector3.ONE*(2.0 if big else 1.0)
 ornaments=Node3D.new();add_child(ornaments)
 if kind=="GlassSovereign":
  for side in [-1,1]:
   for i in 6:
    var crystal=Art.shape(ornaments,Vector3(side*(.6+i*.22),1.8+i*.18,.3),Vector3(.18,.6+i*.09,.16),Color("93d9e5"),"cone")
    crystal.rotation.z=-side*.7
    crystal.material_override=BattleMotion.effect_material(Color("84c8df"),.8)
  orrery=Node3D.new();ornaments.add_child(orrery);orrery.position=Vector3(0,3.6,0)
  for i in 3:
   var ring=MeshInstance3D.new();var torus=TorusMesh.new();torus.inner_radius=.65+i*.13;torus.outer_radius=.7+i*.13;ring.mesh=torus
   ring.material_override=Art.surface(Color("c7a568"),"metal",1);ring.rotation_degrees=Vector3(55,i*60,0);orrery.add_child(ring)
 elif kind in ["IronrootColossus","ForgeSentinel"]:
  var factor=1.6 if big else .9
  for side in [-1,1]:
   var shoulder=Art.shape(ornaments,Vector3(side*.8,1.65,0)*factor,Vector3(.8,.65,.9)*factor,Color("64717a"))
   shoulder.rotation.z=side*.18;shoulder.material_override.metallic=.7;shoulder.material_override.roughness=.38
  var core=Art.shape(ornaments,Vector3(0,1.3,-.52)*factor,Vector3(.45,.65,.15)*factor,Color("ffad66"))
  core.material_override=BattleMotion.effect_material(Color("ed8956"))
  var light=OmniLight3D.new();ornaments.add_child(light);light.position=core.position;light.light_color=Color("ffad66");light.omni_range=5;light.light_energy=1.2
  if big:
   var hammer=GearVisual.item("War Hammer");ornaments.add_child(hammer);hammer.position=Vector3(-1.8,1.9,0);hammer.scale=Vector3.ONE*1.7;hammer.rotation.z=.12
 elif kind=="StormRoc":native.scale=Vector3.ONE*1.3
func motion(moving:bool,sprint:bool=false):
 if native and native.has_method("motion"):native.motion(moving,sprint)
func play_action(label:String)->float:
 if native and native.has_method("play_action"):
  native.battle=battle
  return native.play_action(label)
 return .6
func _process(delta:float):
 clock+=delta
 if orrery:orrery.rotation.y=clock*.3;orrery.rotation.z=sin(clock*.5)*.18

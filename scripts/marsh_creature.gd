class_name MarshCreature
extends Node3D
var battle:=false
var body:Node3D
var native:Node3D
var species:String
var phase:=0.0
func _init(kind:String="BogWisp"):
 species=kind
func _ready():
 body=Node3D.new()
 body.name="Body"
 add_child(body)
 match species:
  "ReedStalker":
   native=CompanionVisual.build("dire_wolf")
   body.add_child(native)
   native.scale=Vector3(1.05,1.1,1.15)
   Art.shape(body,Vector3(0,1.1,0.2),Vector3(.25,.9,.25),Color("9da774"),"cone")
  "DrownedSentinel","ReliquaryKeeper":
   native=CompanionVisual.build("golem")
   body.add_child(native)
   if species=="ReliquaryKeeper":native.scale=Vector3.ONE*1.6
   for x in [-.8,.8]:
    Art.shape(body,Vector3(x,1.7,0),Vector3(.15,.8,.15),Color("45b5b3"),"cone")
   if species=="ReliquaryKeeper":
    var crown=MeshInstance3D.new()
    var ring=TorusMesh.new()
    ring.inner_radius=.34
    ring.outer_radius=.49
    crown.mesh=ring
    crown.position=Vector3(0,3.35,0)
    crown.material_override=Art.surface(Color("b0a276"),"metal",1)
    body.add_child(crown)
    for i in 7:
     var a=i*TAU/7
     Art.shape(body,Vector3(sin(a)*.43,3.53,cos(a)*.43),Vector3(.1,.38,.1),Color("8ecbc0"),"cone")
    # A broken floodgate shield and tide-staff belong to the keeper, not its common sentinels.
    var shield=Art.box(body,Vector3(1.1,1.7,-.15),Vector3(.95,1.8,.22),Color("789f9e"))
    shield.rotation.z=-.15;shield.material_override=Art.surface(Color("789f9e"),"metal",2)
    for row in 4:Art.box(body,Vector3(1.1,1.15+row*.35,-.29),Vector3(.7,.055,.04),Color("d4c695"))
    Art.box(body,Vector3(-1.15,1.8,0),Vector3(.12,3.6,.12),Color("7e7767"))
    Art.shape(body,Vector3(-1.15,3.5,0),Vector3(.6,.8,.6),Color("72dbd9"),"cone")
  "MireLeech":
   for i in range(7):
    Art.shape(body,Vector3(0,.22+sin(i*.45)*.08,(i-3)*.19),Vector3(.5-i*.025,.45,.34),Color("4c665c"))
   for x in [-.14,.14]:Art.shape(body,Vector3(x,.43,-.64),Vector3(.08,.07,.07),Color("f6c27a"))
  _:
   var core=Art.shape(body,Vector3(0,1.15,0),Vector3(.6,.8,.6),Color("7dd8cc"))
   core.material_override.emission_enabled=true
   core.material_override.emission=Color("2eada9")
   for i in range(5):
    var a=i*TAU/5
    Art.shape(body,Vector3(cos(a)*.48,1.1,sin(a)*.48),Vector3(.1,.9,.1),Color("8b9872"),"cone")
   var light=OmniLight3D.new()
   light.light_color=Color("72e3dc")
   light.omni_range=3
   body.add_child(light)
func motion(moving:bool,sprint:bool=false):
 if native and native.has_method("motion"):native.motion(moving,sprint)
func play_action(label:String)->float:
 if native and native.has_method("play_action"):
  native.battle=battle
  return native.play_action(label)
 var tween=create_tween()
 tween.tween_property(body,"rotation:z",.18,.15)
 tween.tween_property(body,"rotation:z",0,.2)
 return .35
func _process(delta:float):
 phase+=delta
 if species=="BogWisp":body.position.y=sin(phase*2)*.18
 if species=="MireLeech":body.rotation.y=sin(phase*2)*.08

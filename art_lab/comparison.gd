extends Control
# F6 runs this scene independently; F5 still runs the unchanged game.
var actors:Array[ArtLabActor]=[]
var cameras:Array[Camera3D]=[]
var viewports:Array[SubViewport]=[]
var clip_labels:Array[Label]=[]
var caption_labels:Array[Label]=[]
var outfit_picker:OptionButton
var vrm_picker:OptionButton
var face_picker:OptionButton
var angle_picker:OptionButton
var mode_picker:OptionButton
var selected_outfit=0
var selected_vrm=0
var selected_face=0
const FACES=["neutral","happy","angry","sad","surprised","blink","aa"]
var cards:HBoxContainer
var note:Label
var title:Label
var mode="Characters"
var motion="Idle"
var turn=0.0
var playing=true
var turntable=false
var face_view=false
var gear_visible=true
var elapsed=0.0
var creature_players:Array[AnimationPlayer]=[]
var creature_models:Array[Node3D]=[]
const TITLES=["LEGACY HERO","A · QUATERNIUS","B · ANIME / VRM"]
const CAPTIONS=["Custom MakeHuman/KayKit derivative\nCurrent production visuals, unchanged","Universal Base + Fantasy Standard derivative\nArtist-authored head, hair, outfit; CC0","Seed-san by VirtualCast, Inc.\nOfficial VRM sample; VRM Public License 1.0"]
func _ready():
 build_ui()
 build_characters()
func make_label(parent:Node,text_:String,size_=16)->Label:
 var label=Label.new()
 label.text=text_
 label.add_theme_font_size_override("font_size",size_)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(label)
 return label
func button(parent:Node,text_:String,action:Callable)->Button:
 var control=Button.new()
 control.text=text_
 parent.add_child(control)
 control.pressed.connect(action)
 return control
func build_ui():
 var background=ColorRect.new()
 background.color=Color("101724")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var margin=MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,16)
 add_child(margin)
 var column=VBoxContainer.new()
 column.add_theme_constant_override("separation",10)
 margin.add_child(column)
 title=make_label(column,"VERDANT OATH · ART DEVELOPMENT LAB",24)
 make_label(column,"Review only · equal height, lighting and camera · gameplay classes, equipment, saves and production models are unchanged",14)
 var toolbar=HBoxContainer.new()
 column.add_child(toolbar)
 var modes=OptionButton.new()
 mode_picker=modes
 for name_ in ["Characters","Wolf comparison","Goblin audit"]:modes.add_item(name_)
 modes.item_selected.connect(func(index):set_mode(modes.get_item_text(index)))
 toolbar.add_child(modes)
 for action in ArtLabActor.MOTIONS:
  var label:String=action
  button(toolbar,action,func():set_motion(label))
 button(toolbar,"Pause / Play",toggle_play)
 button(toolbar,"Restart",func():
  for actor in actors:actor.seek_motion(0)
  for player in creature_players:player.seek(0,true))
 var extras=HBoxContainer.new()
 column.add_child(extras)
 var angles=OptionButton.new()
 angle_picker=angles
 for name_ in ["Front","Three-quarter","Side","Back","Face detail"]:angles.add_item(name_)
 angles.item_selected.connect(func(index):set_camera_view(index))
 extras.add_child(angles)
 button(extras,"Turntable",func():turntable=not turntable)
 button(extras,"Sword / shield",func():
  gear_visible=not gear_visible
  for actor in actors:actor.set_gear_visible(gear_visible))
 var outfits=OptionButton.new()
 outfit_picker=outfits
 outfits.add_item("A: Ranger outfit")
 outfits.add_item("A: Peasant outfit")
 outfits.item_selected.connect(select_outfit)
 extras.add_child(outfits)
 var vrm_models=OptionButton.new()
 vrm_picker=vrm_models
 vrm_models.add_item("B: Seed-san")
 vrm_models.add_item("B: Twist test")
 vrm_models.item_selected.connect(select_vrm_sample)
 extras.add_child(vrm_models)
 var expressions=OptionButton.new()
 face_picker=expressions
 for name_ in ["neutral","happy","angry","sad","surprised","blink","aa"]:expressions.add_item("B face: "+name_)
 expressions.item_selected.connect(select_expression)
 extras.add_child(expressions)
 var speeds=OptionButton.new()
 for speed_ in ["0.5×","1×","1.5×"]:speeds.add_item(speed_)
 speeds.select(1)
 speeds.item_selected.connect(func(index):
  for actor in actors:
   actor.speed=[.5,1.0,1.5][index]
   actor.motion_player.speed_scale=actor.speed if playing else 0)
 extras.add_child(speeds)
 var parts=HBoxContainer.new()
 column.add_child(parts)
 button(parts,"A: Hood on/off",func():
  for actor in actors:actor.toggle_outfit_part("_Head_Hood"))
 button(parts,"A: Pauldrons on/off",func():
  for actor in actors:actor.toggle_outfit_part("_Acc_Pauldrons"))
 button(parts,"B: Native robot accessory on/off",func():
  for actor in actors:actor.toggle_native_accessory())
 make_label(parts,"Outfit names are cosmetic samples, never class restrictions.",13)
 cards=HBoxContainer.new()
 cards.size_flags_vertical=Control.SIZE_EXPAND_FILL
 cards.add_theme_constant_override("separation",12)
 column.add_child(cards)
 note=make_label(column,"",15)
 note.custom_minimum_size.y=48
func clear_cards():
 actors.clear()
 cameras.clear()
 viewports.clear()
 clip_labels.clear()
 caption_labels.clear()
 creature_players.clear()
 creature_models.clear()
 for child in cards.get_children():
  cards.remove_child(child)
  child.queue_free()
func make_stage(heading:String,caption:String)->Dictionary:
 var panel=PanelContainer.new()
 panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var style=StyleBoxFlat.new()
 style.bg_color=Color("202c3c")
 style.border_color=Color("56687c")
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 panel.add_theme_stylebox_override("panel",style)
 cards.add_child(panel)
 var column=VBoxContainer.new()
 panel.add_child(column)
 var label=make_label(column,heading,20)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var desc=make_label(column,caption,13)
 caption_labels.append(desc)
 desc.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 desc.custom_minimum_size.y=44
 var container=SubViewportContainer.new()
 container.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 container.size_flags_vertical=Control.SIZE_EXPAND_FILL
 container.stretch=true
 column.add_child(container)
 var viewport=SubViewport.new()
 viewport.size=Vector2i(400,490)
 viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 viewport.msaa_3d=Viewport.MSAA_4X
 container.add_child(viewport)
 viewports.append(viewport)
 var stage=Node3D.new()
 viewport.add_child(stage)
 var environment=WorldEnvironment.new()
 environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("344354")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color("d4e0ef")
 environment.environment.ambient_light_energy=.22
 stage.add_child(environment)
 var key=DirectionalLight3D.new()
 key.rotation_degrees=Vector3(-35,-25,0)
 key.light_color=Color("fff3dd")
 key.light_energy=.55
 key.shadow_enabled=true
 stage.add_child(key)
 var fill=DirectionalLight3D.new()
 fill.rotation_degrees=Vector3(-20,150,0)
 fill.light_color=Color("a2c5ec")
 fill.light_energy=.15
 stage.add_child(fill)
 var floor_=MeshInstance3D.new()
 var mesh=PlaneMesh.new()
 mesh.size=Vector2(200,200)
 floor_.mesh=mesh
 var mat=StandardMaterial3D.new()
 mat.albedo_color=Color("293847")
 mat.roughness=1
 floor_.material_override=mat
 stage.add_child(floor_)
 var camera=Camera3D.new()
 camera.position=Vector3(0,1.25,5.1)
 camera.fov=30
 stage.add_child(camera)
 camera.look_at(Vector3(0,1.13,0))
 camera.current=true
 cameras.append(camera)
 var clip=make_label(column,"",13)
 clip.custom_minimum_size.y=38
 clip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 clip_labels.append(clip)
 return {"stage":stage,"camera":camera,"clip":clip}
func build_characters():
 clear_cards()
 mode="Characters"
 for index in range(3):
  var stage=make_stage(TITLES[index],CAPTIONS[index])
  var actor=ArtLabActor.new()
  stage.stage.add_child(actor)
  actor.setup(["current","quaternius","vrm_twist" if selected_vrm==1 else "vrm"][index])
  if index==1 and selected_outfit==1:actor.change_outfit(true)
  actor.set_expression(FACES[selected_face])
  actor.rotation.y=turn
  actor.paused=not playing
  actor.set_gear_visible(gear_visible)
  actors.append(actor)
 update_vrm_caption()
 set_motion(motion)
 set_camera_positions()
 note.text="The VRM sample's modern outfit is a style/rig test, not a final fantasy costume. Sword/shield are shared existing reference props; grip offsets still need art calibration. All twelve gameplay classes remain selectable."
func set_mode(which:String):
 mode_picker.select(["Characters","Wolf comparison","Goblin audit"].find(which))
 if which=="Characters":build_characters();return
 clear_cards()
 mode=which
 if which=="Wolf comparison":
  for index in range(2):
   var stage=make_stage("LEGACY WOLF" if index==0 else "QUATERNIUS · ANIMATED WOLF","Generated segmented meshes" if index==0 else "Ultimate Animated Animals · CC0 · real skinned rig")
   var model=CompanionVisual.model("res://assets/models/companions/dire_wolf.glb") if index==0 else load("res://art_lab/assets/quaternius_wolf/Wolf.gltf").instantiate()
   stage.stage.add_child(model)
   var bounds=ArtLabActor.mesh_bounds(model)
   var ratio=1.3/bounds.size.y
   model.scale*=ratio
   model.position.y-=bounds.position.y*ratio
   model.set_meta("review_forward_offset",PI if index==0 else 0.0)
   model.rotation.y=turn+float(model.get_meta("review_forward_offset"))
   creature_models.append(model)
   if index==1:
    var player:AnimationPlayer=model.find_children("*","AnimationPlayer",true,false)[0]
    creature_players.append(player)
   stage.clip.text="Procedural limb motion" if index==0 else "Native Idle / Walk / Gallop / Attack clips"
  note.text="Wolf comparison uses the same lighting, camera and normalized rest-mesh height. Human blocking/spell clips do not apply to quadrupeds; unavailable actions are explicitly reported."
  set_motion(motion)
 else:
  var stage=make_stage("CURRENT FOREST GOBLIN","Generated placeholder · production asset unchanged")
  var model=CompanionVisual.model("res://assets/models/enemies/forest_goblin.glb")
  stage.stage.add_child(model)
  model.set_meta("review_forward_offset",PI)
  creature_models.append(model)
  stage.clip.text="Segmented procedural motion"
  stage=make_stage("REPLACEMENT · NOT CLEARED","No unrelated monster is mislabeled as a goblin")
  stage.clip.text="Bestiary Standard license review required"
  note.text="Bestiary's downloaded license text is QAL v1.0, not blanket CC0: standalone asset redistribution is restricted. No Bestiary model has been downloaded/bundled. See the audit for exact sources and manual acquisition steps."
 set_camera_positions()
func set_motion(label:String):
 motion=label
 for index in range(actors.size()):
  actors[index].play_motion(label)
  clip_labels[index].text=("Native KayKit: "+ArtLabActor.CURRENT[label]) if index==0 else ("Retargeted: "+actors[index].source_clips[label])
 if mode=="Wolf comparison":
  var clip:String={"Idle":"Idle","Walking":"Walk","Running":"Gallop","Sword attack":"Attack"}.get(label,"")
  for player in creature_players:
   if not clip.is_empty():
    player.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
    player.play(clip)
    player.speed_scale=1 if playing else 0
   else:player.pause()
  if clip_labels.size()>1:clip_labels[1].text="Native: "+clip if not clip.is_empty() else "Unavailable on this quadruped rig: "+label
func toggle_play():
 playing=not playing
 for actor in actors:
  actor.paused=not playing
  actor.motion_player.speed_scale=actor.speed if playing else 0
 for player in creature_players:player.speed_scale=1 if playing else 0
func set_camera_view(index:int):
 angle_picker.select(index)
 face_view=index==4
 turn=[0.0,.55,PI/2,PI,0.0][index]
 set_camera_positions()
func set_camera_positions():
 for index in range(cameras.size()):
  var camera=cameras[index]
  var center=Vector3(0,1.98,0)
  if face_view and index<actors.size():
   var actor=actors[index]
   var bone=actor.skeleton.find_bone("head" if actor.kind=="current" else "Head")
   if bone>=0:center=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(bone).origin+Vector3.UP*.1
  camera.position=center+Vector3(0,.02,1.5) if face_view else Vector3(0,1.25,5.1)
  camera.look_at(center if face_view else Vector3(0,1.13,0))
 for actor in actors:actor.rotation.y=turn
 for model in creature_models:model.rotation.y=turn+float(model.get_meta("review_forward_offset",0.0))
func _process(delta):
 elapsed+=delta
 if turntable:
  turn+=delta*.3
  for actor in actors:actor.rotation.y=turn
  for model in creature_models:model.rotation.y=turn+float(model.get_meta("review_forward_offset",0.0))
 if playing and not creature_models.is_empty():Art.animate(creature_models[0],elapsed,motion in ["Walking","Running"])
func _unhandled_input(event):
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_SPACE:toggle_play();get_viewport().set_input_as_handled()

func select_outfit(index:int):
 selected_outfit=index
 outfit_picker.select(index)
 for actor in actors:
  actor.change_outfit(index==1)
  actor.set_gear_visible(gear_visible)
func select_vrm_sample(index:int):
 selected_vrm=index
 vrm_picker.select(index)
 for actor in actors:
  actor.change_vrm_sample(index==1)
  actor.set_gear_visible(gear_visible)
 update_vrm_caption()
 set_camera_positions()
func update_vrm_caption():
 if mode=="Characters" and caption_labels.size()==3:
  caption_labels[2].text=CAPTIONS[2] if selected_vrm==0 else "Twist sample by pixiv Inc. (c) 2022\nOfficial VRM sample; constraint diagnostic"
func select_expression(index:int):
 selected_face=index
 face_picker.select(index)
 for actor in actors:actor.set_expression(FACES[index])

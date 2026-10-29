class_name WeaponPreview
extends SubViewportContainer
var viewport: SubViewport
var pivot: Node3D
var camera: Camera3D
var item_name=""
func _ready():
 custom_minimum_size=Vector2(320,190)
 stretch=true
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 viewport=SubViewport.new()
 viewport.size=Vector2i(350,190)
 viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 add_child(viewport)
 var environment=WorldEnvironment.new()
 environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("18283b")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE
 environment.environment.ambient_light_energy=0.7
 viewport.add_child(environment)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-35,-30,0)
 light.light_energy=1.5
 viewport.add_child(light)
 pivot=Node3D.new()
 viewport.add_child(pivot)
 camera=Camera3D.new()
 camera.fov=35
 camera.near=0.01
 viewport.add_child(camera)
func show_item(value: String):
 item_name=value
 for child in pivot.get_children():
  pivot.remove_child(child)
  child.queue_free()
 var entry:Dictionary=State.equipment_data.get(value,{})
 var model:Node3D
 if entry.get("slot","")=="Chest":
  var appearance=State.hero.profile.duplicate(true);appearance["class"]=State.hero.primary
  model=HeroVisual.new({"Chest":value,"Weapon":"None","Shield":"None"},appearance)
 else:model=GearVisual.item(value)
 pivot.add_child(model)
 var boxes:Array[AABB]=[]
 collect_bounds(model,Transform3D.IDENTITY,boxes)
 var bounds=AABB(Vector3.ZERO,Vector3.ONE*0.1)
 if not boxes.is_empty():
  bounds=boxes[0]
  for box in boxes: bounds=bounds.merge(box)
 model.position-=bounds.get_center()
 pivot.rotation.y=PI+0.35
 camera.position=Vector3(0,0,maxf(0.35,bounds.size.length()*0.5)/sin(deg_to_rad(camera.fov*0.5))*1.15)
func collect_bounds(node: Node3D, parent_transform: Transform3D, boxes: Array[AABB]):
 var transform_=parent_transform*node.transform
 if node is MeshInstance3D and node.mesh!=null: boxes.append(transform_*node.get_aabb())
 for child in node.get_children():
  if child is Node3D: collect_bounds(child,transform_,boxes)
func _process(delta: float):
 if is_instance_valid(pivot): pivot.rotation.y+=delta*0.45

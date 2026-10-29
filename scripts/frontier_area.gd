extends Node3D
@export var region_id="sahir"
@export var dungeon=false
const MECHANISMS=[Vector3(-18,0,0),Vector3(18,0,-18),Vector3(-18,0,-36)]
const BOSS=Vector3(0,0,-37)
const TOMB=Vector3(0,0,-49)
const GUIDE=Vector3(0,0,-8)
const BACK=Vector3(0,0,13)
const ONWARD=Vector3(36,0,-43)
var info:Dictionary
var area=""
var hero:Node3D
var companion:Node3D
var camera:ExplorationCamera
var hud:ExplorationHUD
var dialogue:Dialogue
var options:OptionsPanel
var auto_panel:AutoBattlePanel
var menu:VBoxContainer
var puzzle:VBoxContainer
var treasures:TreasureField
var mobs:Array=[]
var points:Array=[]
var cells:Dictionary={}
var boss:Node3D
var gate:Node3D
var mechanism_models:Array=[]
var yaw=0.0
var pitch=-.5
var clock=0.0
var grace=2.5
var message=""
var pending=0
var transitioning=false
func progress()->Dictionary:return ExpeditionRules.progress(State.hero)
func _ready():
 TravelRules.breadcrumb(region_id,"enter dungeon" if dungeon else "enter wilderness")
 info=ExpeditionRules.regions[region_id]
 area=info.dungeon if dungeon else region_id
 State.hero.journey.region=area
 progress()
 Art.environment_(self)
 # The shared woodland environment supplies a grass plane; these biomes supply their own ground.
 var shared_floor=get_child(get_child_count()-1)
 if shared_floor is MeshInstance3D:remove_child(shared_floor);shared_floor.free()
 for child in get_children():
  if child is WorldEnvironment:
   if dungeon:
    child.environment.background_mode=Environment.BG_COLOR;child.environment.background_color=Color("15202c");child.environment.fog_enabled=false
   elif region_id=="sahir":child.environment.fog_light_color=Color("d1b68b");child.environment.ambient_light_color=Color("e2cfae")
 if dungeon:build_dungeon()
 else:build_region()
 hero=Art.actor("Hero",State.hero.equipment);add_child(hero)
 hero.position=State.return_position
 if not walkable(hero.position):hero.position=Vector3(0,0,3)
 companion=CompanionVisual.build(State.hero.companion.current);add_child(companion);companion.position=hero.position+Vector3(1,0,1)
 camera=ExplorationCamera.new();add_child(camera);camera.current=true
 hud=ExplorationHUD.new();add_child(hud);hud.map.dungeon=dungeon;hud.map.floor_cells=cells
 for pos in (MECHANISMS if dungeon else targets()):hud.map.markers.append({"position":pos,"color":Color("e9cf88")})
 dialogue=Dialogue.new();add_child(dialogue)
 options=OptionsPanel.new();add_child(options)
 auto_panel=AutoBattlePanel.new();add_child(auto_panel)
 auto_panel.fight_requested.connect(func():start_battle(pending,true))
 auto_panel.closed.connect(func():
  grace=3
  if State.hero.hp<=0:get_tree().change_scene_to_file.call_deferred(State.travel_scene()))
 menu=UI.panel(self,Vector2(410,100),Vector2(470,490));menu.get_parent().get_parent().hide()
 UI.label(menu,info.title if dungeon else info.town)
 for pair in [["Inventory & healing","inventory"],["Equipment","equipment"],["Class skill trees","skills"],["Weapon skill trees","weapons"],["Companion","companions"],["Journal","journal"]]:
  var page=pair[1];UI.button(menu,pair[0],func():character(page))
 UI.button(menu,"Settings",options.open)
 UI.button(menu,"Save",func():State.save_game();message="Saved.")
 UI.button(menu,"Return to title",func():State.save_game();get_tree().change_scene_to_file.call_deferred("res://scenes/title.tscn"))
 UI.button(menu,"Close",func():menu.get_parent().get_parent().hide())
 puzzle=UI.panel(self,Vector2(330,110),Vector2(620,470));puzzle.get_parent().get_parent().hide()
 treasures=TreasureField.new(area);add_child(treasures)
 Sound.theme_("sanctuary" if dungeon else "woodland")
 if not accessible():
  message="This road is not yet open. Return along the marked road."
func accessible()->bool:return ExpeditionRules.accessible(State.hero,region_id)
func targets()->Array:
 var result=[]
 for p in info.targets:result.append(Vector3(p[0],0,p[1]))
 return result
func terrain(color_:Color)->ShaderMaterial:
 var material=ShaderMaterial.new();material.shader=load("res://assets/shaders/frontier_ground.gdshader")
 var type_="dirt" if region_id=="sahir" else "grass"
 material.set_shader_parameter("detail",load("res://assets/textures/rpg/"+type_+"_albedo.png"))
 material.set_shader_parameter("normal_detail",load("res://assets/textures/rpg/"+type_+"_normal.png"))
 material.set_shader_parameter("tint",color_)
 return material
func build_region():
 Art.box(self,Vector3(0,-.18,-19),Vector3(240,.3,240),Color.WHITE).material_override=terrain(Color(info.color))
 # A central road branches east and west into explorable loops rather than a narrow causeway.
 for pair in [[Vector3(0,-.005,-17),Vector3(4,.04,70)],[Vector3(-15,.015,-14),Vector3(30,.04,3)],[Vector3(14,.015,-31),Vector3(32,.04,3)],[Vector3(-27,.015,-26),Vector3(3,.04,28)]]:
  Art.box(self,pair[0],pair[1],Color(info.color).lightened(.13)).material_override=terrain(Color(info.color).lightened(.13))
 for pos in [Vector3(-8,0,5),Vector3(8,0,5),Vector3(-8,0,-3),Vector3(8,0,-3)]:VillageArt.cottage(self,pos)
 TownServices.signs(self,region_id)
 MarshArt.npc(self,GUIDE,info.quest_npc,info.npc_class,"Female" if region_id=="sahir" else "Male")
 MarshArt.npc(self,Vector3(4,0,-8),"Scout Laleh" if region_id=="sahir" else "Miner Tova","Ranger","Female")
 for i in 52:
  var rng=RandomNumberGenerator.new();rng.seed=1330+i*31+(500 if region_id=="kharholt" else 0)
  var p=Vector3(rng.randf_range(-43,43),0,rng.randf_range(-62,22))
  if absf(p.x)<13 or targets().any(func(t):return t.distance_to(p)<5):continue
  var size_=Vector3(rng.randf_range(2,5),rng.randf_range(2,6),rng.randf_range(2,5))
  var rock=Art.shape(self,p+Vector3(0,size_.y*.4,0),size_,Color(info.rock))
  rock.material_override=Art.surface(Color(info.rock),"stone",3)
  if region_id=="kharholt" and i%3==0:Art.tree(self,p,1.0)
 for location in info.locations:
  var point=Vector3(location[0],0,location[1])
  Art.sign_(self,point+Vector3(0,3,0),location[2])
  for side in [-1,1]:
   var post=Art.shape(self,point+Vector3(side*2,1.8,0),Vector3(.65,3.6,.65),Color(info.rock),"cylinder")
   post.material_override=Art.surface(Color(info.rock).lightened(.1),"stone",2)
  Art.box(self,point+Vector3(0,3.6,0),Vector3(4.5,.5,.8),Color(info.rock))
 build_landmarks()
 for i in 3:
  var p=targets()[i]
  var tablet=Art.shape(self,p+Vector3(0,.7,0),Vector3(1.3,1.4,1.3),Color("bfb59a"),"cylinder")
  Art.sign_(self,p+Vector3(0,2.4,0),("Mirror inscription" if region_id=="sahir" else "Forge song")+" %s [E]" % (i+1))
 Art.sign_(self,BACK+Vector3(0,2.4,0),"Return to "+("Reedcross" if region_id=="sahir" else "Qasira")+" [E]")
 Art.sign_(self,TOMB+Vector3(0,3.2,0),info.title+" [E]")
 for side in [-1,1]:Art.box(self,TOMB+Vector3(side*2.8,2,-1),Vector3(1.2,4,1.4),Color.WHITE).material_override=Art.surface(Color(info.rock),"stone",2)
 Art.box(self,TOMB+Vector3(0,4,-1),Vector3(6.8,.7,1.5),Color.WHITE).material_override=Art.surface(Color(info.rock),"stone",3)
 if region_id=="sahir":Art.sign_(self,ONWARD+Vector3(0,3,0),"Kharholt Pass [E]")
 for i in info.mobs.size():
  var m=info.mobs[i];spawn(Vector3(m[0],0,m[1]),m[2],(3000 if region_id=="sahir" else 4000)+i)
func build_landmarks():
 if region_id=="sahir":
  var pond=Art.shape(self,Vector3(-34,.025,-12),Vector3(8,.05,6),Color("5ba6ae"),"cylinder")
  var water=ShaderMaterial.new();water.shader=load("res://assets/shaders/water.gdshader")
  water.set_shader_parameter("deep_color",Color("286b77"));water.set_shader_parameter("shallow_color",Color("80bdc0"));pond.material_override=water
  for offset in [Vector3(-4,0,-1),Vector3(3,0,-3),Vector3(4,0,3)]:
   var origin=Vector3(-34,0,-12)+offset
   Art.shape(self,origin+Vector3(0,1.9,0),Vector3(.35,3.8,.35),Color("8c7150"),"cylinder")
   for i in 7:
    var angle=i*TAU/7
    var leaf=Art.shape(self,origin+Vector3(sin(angle)*.9,3.8,cos(angle)*.9),Vector3(.4,.14,2.6),Color("6f9b5b"))
    leaf.rotation.y=angle;leaf.rotation.z=.1
  for i in 4:
   var plank=Art.box(self,Vector3(29+i*.3,.4+i*.12,-30),Vector3(2,.16,.25),Color.WHITE)
   plank.rotation.z=.4;plank.material_override=Art.surface(Color("b0926d"),"wood",1)
  VillageArt.piece(self,"Prop_Crate",Vector3(30,0,-32),Vector3(1.2,1.1,1.2))
 else:
  for i in 9:
   var x=-56 if i%2==0 else 56
   var mass=Art.shape(self,Vector3(x,5,-62+i*10),Vector3(25,28+sin(i)*8,22),Color(info.rock))
   mass.material_override=Art.surface(Color(info.rock),"stone",9)
  for point in [Vector3(-25,0,-37),Vector3(-21,0,-40)]:
   VillageArt.piece(self,"Prop_Crate",point,Vector3(1.1,.9,1.1))
   Art.box(self,point+Vector3(0,.9,0),Vector3(2,.1,1.3),Color("8e8b75"))
func build_dungeon():
 cells=RoomLayout.expedition()
 RoomLayout.build(self,cells,Color("917a65") if region_id=="sahir" else Color("626d72"))
 for pos in [Vector3.ZERO,Vector3(-18,0,0),Vector3(0,0,-18),Vector3(18,0,-18),Vector3(-18,0,-36),BOSS]:
  for x in [-4,4]:MarshArt.lantern(self,pos+Vector3(x,0,-3))
  var ring=Art.shape(self,pos+Vector3(0,.03,0),Vector3(5,.05,5),Color("b8a478"),"cylinder")
 for i in MECHANISMS.size():
  var p=MECHANISMS[i]
  Art.shape(self,p+Vector3(0,.75,0),Vector3(1.4,1.5,1.4),Color(info.rock),"cylinder")
  if region_id=="sahir":
   var mirror=Art.box(self,p+Vector3(0,1.7,0),Vector3(1.5,1.5,.12),Color("a4dfdf"));mirror.rotation.y=i*.5
   mirror.material_override=Art.surface(Color("a4dfdf"),"metal",1)
   var beam_root=Node3D.new();add_child(beam_root);beam_root.position=p+Vector3(0,1.7,0)
   var beam=Art.box(beam_root,Vector3(0,0,-2),Vector3(.045,.045,4),Color("f3d995"))
   beam.material_override=BattleMotion.effect_material(Color("f3d995"),.75)
   mechanism_models.append({"mirror":mirror,"beam":beam_root})
  else:
   var wheel=Art.shape(self,p+Vector3(0,1.6,0),Vector3(1.8,.25,1.8),Color("b78f60"),"cylinder")
   mechanism_models.append({"mirror":wheel})
  Art.sign_(self,p+Vector3(0,3,0),("Sun mirror" if region_id=="sahir" else "Steam lift")+" %s [E]" % (i+1))
 Art.sign_(self,Vector3(0,2.4,3),"[E] Return to "+info.name)
 Art.sign_(self,Vector3(0,2.4,-18),"DAWN faces EAST · DUSK faces WEST · MOON faces SOUTH" if region_id=="sahir" else "Cool the west anvil, then vent the east. Watchers carry the valve keys.")
 gate=Art.box(self,Vector3(0,1.5,-28),Vector3(5.5,3,.5),Color("a38d67"));gate.material_override=Art.surface(Color("a38d67"),"metal",2)
 boss=Art.actor("GlassSovereign" if region_id=="sahir" else "IronrootColossus")
 add_child(boss);boss.position=BOSS
 Art.sign_(self,BOSS+Vector3(0,5,0),"NAMARRA · GLASSWING SOVEREIGN" if region_id=="sahir" else "VORR · THE MOUNTAIN THAT KNEELS")
 var foes=["dune_scarab","glass_wisp","sand_drake","dune_scarab","glass_wisp"] if region_id=="sahir" else ["forge_sentinel","crag_hound","forge_sentinel","storm_roc","forge_sentinel"]
 var homes=[Vector3(-12,0,0),Vector3(12,0,-18),Vector3(0,0,-16),Vector3(-18,0,-29),Vector3(-18,0,-38)]
 for i in foes.size():spawn(homes[i],foes[i],(3100 if region_id=="sahir" else 4100)+i)
func spawn(point:Vector3,species:String,id:int):
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))[species]
 var model=Art.actor(data.model);add_child(model);model.position=point
 Art.sign_(model,Vector3(0,2.6,0),data.name)
 mobs.append({"model":model,"species":species,"id":id});points.append(point)
func modal()->bool:return transitioning or dialogue.active or options.active or auto_panel.active or menu.get_parent().get_parent().visible or puzzle.get_parent().get_parent().visible
func walkable(p:Vector3)->bool:
 if dungeon:
  if p.z< -28 and absf(p.x)<9 and not ExpeditionRules.can_open(State.hero,region_id):return false
  return RoomLayout.contains(cells,p)
 if absf(p.x)>43 or p.z< -65 or p.z>25:return false
 for h in [Vector3(-8,0,5),Vector3(8,0,5),Vector3(-8,0,-3),Vector3(8,0,-3)]:
  if absf(p.x-h.x)<2.5 and absf(p.z-h.z)<2.4:return false
 return true
func _process(delta):
 clock+=delta;grace=maxf(0,grace-delta)
 var direction=Vector3.ZERO
 if not modal():
  var orbit=CameraOrbit.step(yaw,pitch,delta);yaw=orbit.x;pitch=orbit.y
  direction=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).rotated(Vector3.UP,yaw).normalized()
  hero.position=ExplorationMotion.move(hero.position,direction*(7.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.3)*State.travel_multiplier()*delta,walkable)
  if direction.length()>0:hero.rotation.y=lerp_angle(hero.rotation.y,atan2(-direction.x,-direction.z),minf(1,delta*12))
 State.remember_position(hero.position);Art.animate(hero,clock,direction.length()>0)
 companion.visible=State.hero.companion.active
 var target=hero.position+Vector3(1,0,1.5);var moving=companion.position.distance_to(target)>.4
 companion.position=companion.position.lerp(target,minf(1,delta*4));Art.animate(companion,clock,moving)
 camera.update_view(hero.position+Vector3.UP*1.2,Vector3(sin(yaw)*cos(pitch)*8,-sin(pitch)*8+.3,cos(yaw)*cos(pitch)*8),delta)
 for i in mobs.size():
  var mob=mobs[i];mob.model.visible=not progress().rooms.has(str(mob.id)) if dungeon else Time.get_ticks_msec()>int(State.cleared_until.get(mob.id,0))
  Art.animate(mob.model,clock,false)
  if not modal() and grace<=0 and mob.model.visible and hero.position.distance_to(mob.model.position)<1.4 and State.hero.hp>0 and State.starter_ready():start_battle(i);return
 if dungeon:
  for i in mechanism_models.size():
   if region_id=="sahir":
    mechanism_models[i].mirror.rotation.y=int(progress().mirrors[i])*PI/2
    mechanism_models[i].beam.rotation.y=int(progress().mirrors[i])*PI/2
   else:mechanism_models[i].mirror.rotation.y=PI/2 if progress().lifts.has("west" if i==0 else "east") else 0
  gate.visible=not ExpeditionRules.can_open(State.hero,region_id)
  boss.visible=not progress().cleared.has(region_id);Art.animate(boss,clock,false)
  if not modal() and grace<=0 and boss.visible and hero.position.distance_to(BOSS)<2.5:boss_intro();return
 hud.update_view(hero.position,ExpeditionRules.goal(State.hero,region_id),prompt(),State.notice if not State.notice.is_empty() else message,delta)
func prompt()->String:
 if not treasures.nearby(hero.position).is_empty():return "[E] Open treasure chest"
 if dungeon:
  if hero.position.z>1:return "[E] Return to "+info.name
  for p in MECHANISMS:
   if hero.position.distance_to(p)<2.4:return "[E] Inspect chamber mechanism"
  if hero.position.distance_to(BOSS)<4:return "[E] Speak with the guardian"
  return "Explore the side chambers · Supplies are limited · [Tab] Heal"
 if hero.position.distance_to(GUIDE)<2.5:return "[E] Speak with "+info.quest_npc
 if hero.position.distance_to(Vector3(4,0,-8))<2.5:return "[E] Optional bounty"
 var door=TownServices.nearby(region_id,hero.position)
 if not door.is_empty():return "[E] Enter "+door[2]
 if hero.position.distance_to(TOMB)<3:return "[E] Enter "+info.title
 if hero.position.distance_to(BACK)<3:return "[E] Return along the road"
 if region_id=="sahir" and hero.position.distance_to(ONWARD)<3:return "[E] Kharholt Pass"
 for p in targets():
  if hero.position.distance_to(p)<2.5:return "[E] Read the ancient inscription"
 return "Explore the paths, ruins and wilderness · Arrow keys / RMB orbit"
func interact():
 if modal():return
 State.notice=""
 if treasures.open_near(hero.position):return
 if dungeon:
  if hero.position.z>1:travel(region_id,Vector3(0,0,-46));return
  for i in MECHANISMS.size():
   if hero.position.distance_to(MECHANISMS[i])<2.4:mechanism(i);return
  if hero.position.distance_to(BOSS)<4:boss_intro()
  return
 var door=TownServices.nearby(region_id,hero.position)
 if not door.is_empty():TownServices.enter(get_tree(),region_id,door);return
 if hero.position.distance_to(GUIDE)<2.5:
  var ready=ExpeditionRules.count(State.hero,region_id)==3
  dialogue.show_id(region_id+("_after" if progress().cleared.has(region_id) else ("_key" if ready else "_intro")),func():
   if ready and not progress().briefed.has(region_id):
    progress().briefed.append(region_id);State.award_xp(int(info.reward_xp));State.award_gold(int(info.reward_gold),"Ancient route uncovered")
   State.save_game())
  return
 if hero.position.distance_to(Vector3(4,0,-8))<2.5:side_quest();return
 for i in 3:
  if hero.position.distance_to(targets()[i])<2.5:
   var id=region_id+str(i)
   if not progress().inscriptions.has(id):progress().inscriptions.append(id);State.save_game()
   dialogue.show_id(region_id+"_tablet_"+str(i));return
 if hero.position.distance_to(TOMB)<3:
  if progress().briefed.has(region_id):travel(info.dungeon,Vector3(0,0,3))
  else:message="Find the three inscriptions and speak with "+info.quest_npc+"."
 elif hero.position.distance_to(BACK)<3:travel(info.prior,Vector3(0,0,-16) if region_id=="sahir" else ONWARD+Vector3(0,0,3))
 elif region_id=="sahir" and hero.position.distance_to(ONWARD)<3:
  if progress().cleared.has("sahir"):travel("kharholt",Vector3(0,0,10))
  else:message="Glass storms close the pass. Quiet the tomb's guardian first."
func mechanism(index:int):
 if index<0 or index>=MECHANISMS.size():return
 TravelRules.breadcrumb(area,"mechanism "+str(index))
 for child in puzzle.get_children():puzzle.remove_child(child);child.queue_free()
 puzzle.get_parent().get_parent().show()
 if region_id=="sahir":
  UI.label(puzzle,"MIRROR %s — THE MEMORY OF THE SUN" % (index+1))
  UI.label(puzzle,["Dawn reaches for the eastern sky.","Dusk watches the western sand.","The moon looks south toward the living."][index])
  UI.label(puzzle,"Facing: "+["North","East","South","West"][progress().mirrors[index]])
  UI.button(puzzle,"Rotate mirror clockwise",func():progress().mirrors[index]=(int(progress().mirrors[index])+1)%4;State.save_game();mechanism(index))
  UI.label(puzzle,"All three beams align. The guardian chamber is open." if ExpeditionRules.can_open(State.hero,region_id) else "A beam waits for the other chambers.")
 else:
  UI.label(puzzle,"STEAMWORKS — "+["Western anvil","Eastern vent","Miner’s memorial"][index])
  var key="west" if index==0 else "east"
  var guardian="4100" if index==0 else "4101"
  var ready=progress().rooms.has(guardian) and (index==0 or progress().lifts.has("west"))
  UI.label(puzzle,"Defeat the chamber watcher before using its valve. Cool west before opening east." if index<2 else "The miners wrote every name here. Vorr refuses to leave them behind. An optional vault lies nearby.")
  if index<2:
   UI.button(puzzle,"Cool west anvil" if index==0 else "Vent east pressure",func():
    if not progress().lifts.has(key):progress().lifts.append(key)
    State.save_game();mechanism(index)).disabled=not ready or progress().lifts.has(key)
 UI.button(puzzle,"Return to chamber",func():puzzle.get_parent().get_parent().hide())
func side_quest():
 var species="sand_drake" if region_id=="sahir" else "crag_hound"
 var n=int(State.hero.side_quests.get(species,0))
 if n>=3 and not progress().side_claimed.has(region_id):
  progress().side_claimed.append(region_id);State.award_gold(180 if region_id=="sahir" else 280,"Trail bounty");State.award_xp(260 if region_id=="sahir" else 400);State.hero.potions+=2;State.save_game()
  message="Bounty paid. Two potions, gold and experience received."
 else:message=("Bounty already paid. Safe travels." if progress().side_claimed.has(region_id) else "Trail bounty: defeat three "+("Sandglass Drakes" if region_id=="sahir" else "Ironfang Hounds")+". Progress: %s/3. Return here for gold, XP and supplies." % n)
func start_battle(index:int,force=false):
 if modal() or State.hero.hp<=0:return
 pending=index
 State.enemy_id=mobs[index].species;State.encounter_id=mobs[index].id
 State.remember_position(hero.position);State.save_game()
 if State.species_wins(State.enemy_id)>=10 and not force:auto_panel.open(State.enemy_id,true)
 else:
  transitioning=true
  get_tree().change_scene_to_file.call_deferred("res://scenes/battle.tscn")
func boss_intro():
 if progress().cleared.has(region_id):dialogue.show_id(region_id+"_boss_after");return
 if not ExpeditionRules.can_open(State.hero,region_id):message="The guardian chamber is still sealed.";return
 dialogue.show_id(region_id+"_boss_before",func():
  transitioning=true
  State.enemy_id=info.boss;State.encounter_id=int(info.boss_id);State.remember_position(hero.position);State.save_game()
  get_tree().change_scene_to_file.call_deferred("res://scenes/battle.tscn"))
func travel(destination:String,pos:Vector3):
 if transitioning:return
 transitioning=true
 TravelRules.breadcrumb(area,"travel "+destination)
 State.hero.journey.region=destination;State.remember_position(pos);State.save_game()
 get_tree().change_scene_to_file.call_deferred(State.travel_scene())
func character(page:String):
 if transitioning:return
 transitioning=true
 State.menu_page=page;State.save_game();get_tree().change_scene_to_file.call_deferred("res://scenes/character.tscn")
func _unhandled_input(event):
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not modal():yaw-=event.relative.x*.005*UserSettings.camera_sensitivity;pitch=clampf(pitch-event.relative.y*.004*UserSettings.camera_sensitivity,-1.1,-.15)
 if not event is InputEventKey or not event.pressed or event.echo:return
 if dialogue.active or options.active or auto_panel.active:return
 if event.keycode==KEY_ESCAPE:
  if puzzle.get_parent().get_parent().visible:puzzle.get_parent().get_parent().hide()
  else:menu.get_parent().get_parent().visible=not menu.get_parent().get_parent().visible
  return
 if modal():return
 match event.keycode:
  KEY_E:interact()
  KEY_TAB:character("inventory")
  KEY_I:character("equipment")
  KEY_K:character("skills")
  KEY_C:character("companions")
  KEY_J:character("journal")
  KEY_F5:State.save_game();message="Saved."

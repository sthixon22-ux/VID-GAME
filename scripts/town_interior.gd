extends Node3D
var hero:HeroVisual
var companion:Node3D
var camera:ExplorationCamera
var hud:ExplorationHUD
var options:OptionsPanel
var panel:VBoxContainer
var yaw:=0.0
var pitch:=-.45
var elapsed:=0.0
var service="weapons"
var town="forest"
var title="Town service"
var message=""
func _ready():
 var visit:Dictionary=State.hero.get("town_visit",{})
 town=visit.get("region","forest")
 service=visit.get("service","weapons")
 title=visit.get("name","Town service")
 State.shop_id=TownServices.shop(town,service)
 build()
 hero=Art.actor("Hero",State.hero.equipment)
 add_child(hero)
 hero.position=State.return_position
 if not walkable(hero.position):hero.position=Vector3(0,0,3.5)
 companion=CompanionVisual.build(State.hero.companion.current)
 add_child(companion)
 companion.position=hero.position+Vector3(1,0,1)
 camera=ExplorationCamera.new();add_child(camera);camera.current=true
 hud=ExplorationHUD.new();add_child(hud);hud.map.hide()
 options=OptionsPanel.new();add_child(options)
 panel=UI.panel(self,Vector2(390,170),Vector2(500,370))
 panel.get_parent().get_parent().hide()
 Sound.theme_("woodland")
func build():
 Art.studio(self)
 var pedestal=get_child(get_child_count()-1)
 remove_child(pedestal);pedestal.free()
 for child in get_children():
  if child is WorldEnvironment:
   child.environment.background_mode=Environment.BG_COLOR
   child.environment.background_color=Color("222c35")
 if service in ["weapons","armor"]:
  for x in [-4,0,4]:
   for z in [-4,0,4]:VillageArt.piece(self,"Floor_UnevenBrick",Vector3(x,-.16,z),Vector3(4,.13,4))
 else:Art.box(self,Vector3(0,-.12,0),Vector3(12,.2,12),Color.WHITE).material_override=Art.surface(Color("a2927c"),"wood",4)
 var rug=Art.box(self,Vector3(0,-.01,.4),Vector3(2.6,.025,3.2),Color.WHITE)
 rug.material_override=Art.surface(Color("637d83") if service=="inn" else Color("8b645b"),"fabric",3)
 for x in [-5.83,5.83]:VillageArt.piece(self,"Window_Wide_Flat1",Vector3(x,1.7,-.5),Vector3(1.3,1.3,.12),PI/2 if x<0 else -PI/2)
 for x in [-4.8,4.8]:VillageArt.piece(self,"Prop_Crate",Vector3(x,0,4),Vector3(.75,.75,.75))
 for x in [-6,6]:
  Art.box(self,Vector3(x,1.7,0),Vector3(.22,3.4,12),Color.WHITE).material_override=Art.surface(Color("c2b49c"),"plaster",4)
  CameraObstacles.box(self,Vector3(x,1.7,0),Vector3(.22,3.4,12))
 CameraObstacles.box(self,Vector3(0,1.7,-6),Vector3(12,3.4,.22))
 Art.box(self,Vector3(0,1.7,-6),Vector3(12,3.4,.22),Color.WHITE).material_override=Art.surface(Color("c2b49c"),"plaster",4)
 # Roof cutaway: perimeter framing leaves the orbit camera's sightline clear.
 for x in [-5.8,5.8]:
  for z in [-5.8,0.0,5.8]:Art.box(self,Vector3(x,1.6,z),Vector3(.18,3.2,.18),Color("64513c"))
 Art.box(self,Vector3(0,3.2,-5.8),Vector3(12,.18,.18),Color("64513c"))
 Art.box(self,Vector3(0,.75,-2.3),Vector3(4,.25,1.2),Color.WHITE).material_override=Art.surface(Color("998566"),"wood",2)
 Art.box(self,Vector3(0,.35,-1.8),Vector3(3.8,.7,.13),Color.WHITE).material_override=Art.surface(Color("7d684f"),"wood",2)
 for x in [-1.7,1.7]:
  for z in [-1.9,-2.7]:Art.box(self,Vector3(x,.35,z),Vector3(.14,.7,.14),Color("66513c"))
 var npc=HeroVisual.new({"Weapon":"None","Chest":"Traveler's Clothing","Shield":"None"},{"class":"Healer" if service in ["inn","items"] else "Warrior","sex":"Female" if town=="mirefen" else "Male"})
 add_child(npc);npc.position=Vector3(0,0,-3.6);npc.rotation.y=PI
 Art.sign_(self,Vector3(0,2.6,-2.3),title+" [E]")
 Art.sign_(self,Vector3(0,2,5.2),"[E] Leave building")
 for side in [-1,1]:
  for x in [-.9,.9]:Art.box(self,Vector3(side*4.5+x,1.05,-4.8),Vector3(.1,2.1,.14),Color("705b43"))
  for row in 3:
   Art.box(self,Vector3(side*4.5,.5+row*.6,-4),Vector3(2.1,.10,2),Color("7c694f"))
  if service=="inn":
   Art.box(self,Vector3(side*4.3,.45,1.5),Vector3(1.7,.6,2.8),Color("655443"))
   Art.box(self,Vector3(side*4.3,.8,1.5),Vector3(1.6,.12,2.7),Color("6c8b92"))
   Art.box(self,Vector3(side*4.3,.92,.7),Vector3(1.3,.16,.6),Color("d0c5ac"))
  else:
   var stock=ShopBook.stock(State.shop_id) if service!="items" else ["potion","ether","treat"]
   for i in mini(3,stock.size()):
    var prop=GearVisual.item(stock[i]);add_child(prop)
    prop.position=Vector3(side*4.5,.7+i*.6,-3.8)
    prop.scale=Vector3.ONE*.45
 for x in [-3,3]:
  var light=OmniLight3D.new();add_child(light)
  light.position=Vector3(x,2.8,-2)
  light.light_color=Color("ffdcab");light.light_energy=.65;light.omni_range=7
func walkable(pos:Vector3)->bool:
 if absf(pos.x)>5.5 or pos.z>5.5 or pos.z< -5.5:return false
 if pos.z< -1.2 and absf(pos.x)<2.3 and pos.z> -3.1:return false
 if absf(pos.x)>3.2 and (pos.z< -2.5 or service=="inn"):return false
 return true
func _process(delta:float):
 elapsed+=delta
 var moving=false
 if not options.active and not panel.get_parent().get_parent().visible:
  var direction=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).rotated(Vector3.UP,yaw).normalized()
  moving=direction.length()>.1
  hero.position=ExplorationMotion.move(hero.position,direction*delta*4.3,walkable)
  if moving:hero.rotation.y=lerp_angle(hero.rotation.y,atan2(-direction.x,-direction.z),minf(1,delta*12))
 State.remember_position(hero.position)
 Art.animate(hero,elapsed,moving)
 companion.visible=State.hero.companion.active
 var follow=hero.position+Vector3(1,0,1)
 Art.animate(companion,elapsed,companion.position.distance_to(follow)>.3)
 companion.position=companion.position.lerp(follow,minf(1,delta*4))
 camera.update_view(hero.position+Vector3.UP*1.2,Vector3(sin(yaw)*7.5,-sin(pitch)*7.5+.3,cos(yaw)*cos(pitch)*7.5),delta)
 var prompt="[E] Leave" if hero.position.distance_to(Vector3(0,0,5))<2 else ("[E] Speak to innkeeper" if service=="inn" else "[E] Browse stock") if hero.position.distance_to(Vector3(0,0,-1))<2 else "Walk to the counter · [Tab] Inventory"
 hud.update_view(hero.position,title,prompt,message,delta)
func _unhandled_input(event):
 if options.active:return
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  yaw-=event.relative.x*.005*UserSettings.camera_sensitivity
  pitch=clampf(pitch-event.relative.y*.004,-1.1,-.2)
 if not event is InputEventKey or not event.pressed or event.echo:return
 match event.keycode:
  KEY_E:interact()
  KEY_ESCAPE:
   if panel.get_parent().get_parent().visible:panel.get_parent().get_parent().hide()
   else:options.open()
  KEY_TAB:character("inventory")
  KEY_I:character("equipment")
  KEY_K:character("skills")
  KEY_C:character("companions")
  KEY_J:character("journal")
  KEY_F5:State.save_game()
  KEY_F9:
   State.load_game();get_tree().change_scene_to_file(State.travel_scene())
func interact():
 if options.active or panel.get_parent().get_parent().visible:return
 if hero.position.distance_to(Vector3(0,0,5))<2:leave()
 elif hero.position.distance_to(Vector3(0,0,-1))<2:
  if service!="inn":character("shop")
  else:
   for child in panel.get_children():child.queue_free()
   UI.label(panel,title)
   UI.label(panel,"A room and warm meal restore HP, MP and companion HP.\nPrice: %s gold · You have %s gold." % [TownServices.inn_price(town),State.hero.gold])
   UI.button(panel,"Stay · %s gold" % TownServices.inn_price(town),rest).disabled=State.hero.gold<TownServices.inn_price(town)
   UI.button(panel,"Not now",func():panel.get_parent().get_parent().hide())
   panel.get_parent().get_parent().show()
func rest():
 if TownServices.rest(town):message="Rested. HP, MP and companion restored."
 else:message="You need more gold for a room."
 panel.get_parent().get_parent().hide()
func leave():
 var visit=State.hero.town_visit
 State.hero.journey.region=visit.region
 var pos=visit.position
 State.remember_position(Vector3(pos[0],pos[1],pos[2]))
 State.save_game()
 get_tree().change_scene_to_file(State.travel_scene())
func character(page:String):
 State.menu_page=page
 State.remember_position(hero.position)
 State.save_game()
 get_tree().change_scene_to_file("res://scenes/character.tscn")

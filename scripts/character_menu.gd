extends Node
var page="equipment"
var selected_class="Paladin"
var slot="Weapon"
var selected_skill="oath"
var weapon_family="sword"
var weapon_node="edge"
var body: Control
var preview: SubViewport
var preview_root: Node3D
var preview_actor: Node3D
var shop_preview: WeaponPreview
var shop_info: Label
var graph: SkillGraph
var info: VBoxContainer
var point_label: Label
var header_title: Label
var time_=0.0
var model_yaw=PI+0.35
var pending_companion=""
func _ready():
 selected_class=State.hero.primary
 var layer=CanvasLayer.new()
 add_child(layer)
 var backdrop=ColorRect.new()
 backdrop.color=Color("0d1627")
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layer.add_child(backdrop)
 var header=UI.panel(self,Vector2(20,16),Vector2(1240,100))
 header_title=UI.label(header,"")
 header_title.add_theme_font_size_override("font_size",25)
 var tabs=HBoxContainer.new()
 header.add_child(tabs)
 UI.button(tabs,"Equipment",func(): show_page("equipment"))
 UI.button(tabs,"Class trees",func(): show_page("skills"))
 UI.button(tabs,"Weapons",func(): show_page("weapons"))
 UI.button(tabs,"Companion",func(): show_page("companions"))
 UI.button(tabs,"Inventory",func(): show_page("inventory"))
 UI.button(tabs,"Journal",func(): show_page("journal"))
 UI.button(tabs,"Return  [Esc]",leave)
 body=Control.new()
 body.position=Vector2(0,125)
 body.size=Vector2(1280,590)
 layer.add_child(body)
 show_page(State.menu_page)
func clear_body():
 for child in body.get_children():
  body.remove_child(child)
  child.queue_free()
 shop_preview=null
 shop_info=null
 preview_actor=null
 preview=null
 graph=null
func content_panel(pos: Vector2, size_: Vector2) -> VBoxContainer:
 # Reparent the generated panel out of its helper CanvasLayer into this page.
 var box=UI.panel(body,Vector2.ZERO,size_)
 var panel=box.get_parent().get_parent()
 var layer_=panel.get_parent()
 layer_.remove_child(panel)
 body.add_child(panel)
 panel.position=pos
 layer_.queue_free()
 return box
func show_page(which: String):
 page=which
 header_title.text="%s / %s · LEVEL %s · %s GOLD" % [State.hero.profile.name,State.hero.primary,State.hero.level,State.hero.gold]
 clear_body()
 match which:
  "skills": build_skills()
  "shop": build_shop()
  "companions": build_companions()
  "weapons": build_weapons()
  "journal": build_journal()
  "inventory": build_inventory()
  _: build_equipment()
 constrain_page(body)
func build_equipment():
 var slots=content_panel(Vector2(20,0),Vector2(310,570))
 UI.label(slots,"EQUIPPED GEAR").add_theme_font_size_override("font_size",22)
 for key in State.hero.equipment:
  var selected: String=key
  UI.button(slots,"%s\n%s" % [key,State.hero.equipment[key]],func():
   slot=selected
   show_page("equipment"))
 var viewport_container=SubViewportContainer.new()
 viewport_container.position=Vector2(345,0)
 viewport_container.size=Vector2(450,450)
 viewport_container.stretch=true
 body.add_child(viewport_container)
 preview=SubViewport.new()
 preview.size=Vector2i(450,450)
 preview.own_world_3d=true
 viewport_container.add_child(preview)
 preview_root=Node3D.new()
 preview.add_child(preview_root)
 Art.studio(preview_root)
 preview_actor=Art.actor("Hero",State.hero.equipment)
 preview_root.add_child(preview_actor)
 preview_actor.rotation.y=model_yaw
 var camera=Camera3D.new()
 preview_root.add_child(camera)
 camera.fov=36
 camera.position=Vector3(0,1.5,4.8)
 camera.look_at(Vector3(0,1.2,0))
 camera.current=true
 var stats=content_panel(Vector2(345,450),Vector2(450,120))
 var attributes=State.stats()
 UI.label(stats,GameRules.summary(attributes))
 UI.label(stats,"Dodge %.1f%% · bonus-gold chance %.1f%% (+25%% gold)" % [GameRules.dodge_chance(attributes.dexterity)*100,GameRules.gold_chance(attributes.dexterity)*100])
 var row=HBoxContainer.new()
 stats.add_child(row)
 UI.button(row,"Rotate left",func(): model_yaw-=0.55)
 UI.button(row,"Rotate right",func(): model_yaw+=0.55)
 var options=content_panel(Vector2(810,0),Vector2(450,570))
 UI.label(options,"CHOOSE %s" % slot.to_upper()).add_theme_font_size_override("font_size",22)
 UI.label(options,"Owned items · buy new gear at the outfitter" if State.hero.profile.economy else "Legacy wardrobe · owned gear preserved")
 var items: Array=[]
 for item in State.equipment_data:
  if State.equipment_data[item].slot==slot and State.owns(item): items.append(item)
 items.append("None")
 for item in items:
  var name_: String=item
  var data: Dictionary=State.equipment_data.get(item,{"attack":0,"defense":0})
  var old: Dictionary=State.equipment_data.get(State.hero.equipment[slot],{"attack":0,"defense":0})
  var difference={}
  for key in GameRules.STAT_KEYS: difference[key]=int(data.get(key,0))-int(old.get(key,0))
  var button=UI.button(options,"%s%s\n%s" % ["✓ " if State.hero.equipment[slot]==item else "",item,GameRules.summary(difference,true)],func():
   State.equip(slot,name_)
   Sound.cue("confirm")
   show_page("equipment"))
  button.tooltip_text="Change visible gear and derived stats. Two-handed weapons stow your shield."
  button.disabled=item!="None" and (not State.compatible(item) or (slot=="Shield" and GameRules.two_handed(State.equipment_data.get(State.hero.equipment.Weapon,{}))))
 if items.size()==1: UI.label(options,"No equipment owned for this slot.
Visit the outfitter beside the village camp.")
func build_skills():
 var heading=content_panel(Vector2(20,0),Vector2(1240,82))
 var tabs=HBoxContainer.new()
 heading.add_child(tabs)
 var picker=OptionButton.new()
 picker.custom_minimum_size=Vector2(245,38)
 for class_ in State.classes: picker.add_item(class_+(" · PRIMARY" if State.hero.primary==class_ else ""))
 picker.select(State.classes.keys().find(selected_class))
 picker.item_selected.connect(func(index):
  selected_class=State.classes.keys()[index]
  selected_skill="oath"
  show_page("skills"))
 tabs.add_child(picker)
 UI.label(tabs,"Loadout: %s / %s / %s" % [State.hero.primary,State.hero.secondary[0],State.hero.secondary[1]]).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 point_label=UI.label(heading,"Available skill points: %s · %s mastery: %s victories · Gold nodes are learned." % [State.hero.points,selected_class,State.hero.class_mastery[selected_class]])
 graph=SkillGraph.new()
 graph.position=Vector2(25,90)
 graph.size=Vector2(845,470)
 body.add_child(graph)
 graph.configure(selected_class)
 graph.selected_id=selected_skill
 graph.selected.connect(func(id):
  selected_skill=id
  refresh_skill_info())
 info=content_panel(Vector2(895,90),Vector2(365,470))
 refresh_skill_info()
func refresh_skill_info():
 for child in info.get_children():
  info.remove_child(child)
  child.queue_free()
 var node=State.skill_node(selected_class,selected_skill)
 UI.label(info,selected_class.to_upper()+" / "+node.name).add_theme_font_size_override("font_size",21)
 var description=UI.label(info,node.description)
 description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 description.custom_minimum_size=Vector2(300,75)
 var learned=State.hero.skills[selected_class].has(node.id)
 var missing: Array=[]
 for requirement in node.requires:
  if not State.hero.skills[selected_class].has(requirement): missing.append(State.skill_node(selected_class,requirement).name)
 var state="LEARNED" if learned else ("Requires: "+", ".join(missing) if not missing.is_empty() else "Available to learn")
 UI.label(info,"%s\nCost: %s skill points\nPoints available: %s" % [state,int(node.cost),State.hero.points])
 if node.id=="mythic":
  var label=UI.label(info,"AVAILABLE IN COMBAT" if learned and State.hero.primary==selected_class else "Requires level 50 and this class PRIMARY.\nUnlock stays saved when switching classes.")
  label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var learn=UI.button(info,"Learn skill" if not learned else "Already learned",func():
  State.invest_skill(selected_class,selected_skill)
  Sound.cue("confirm")
  show_page("skills"))
 var mastery_needed=int(node.get("mastery_required",0))
 UI.label(info,"%s · Hero level %s / %s required\nClass mastery %s / %s required" % [node.rarity,State.hero.level,int(node.level_required),State.hero.class_mastery[selected_class],mastery_needed])
 learn.disabled=learned or not missing.is_empty() or State.hero.points<int(node.cost) or State.hero.level<int(node.level_required) or State.hero.class_mastery[selected_class]<mastery_needed or not State.active_classes().has(selected_class)
 UI.label(info,"Your three classes and primary role are locked for this demo. Class reassignment belongs to a later chapter.\nEach full tree costs 50 SP; capstone at level 50. Earn 2 shared SP per level.\nGold nodes are learned. Lines show prerequisites.")
 constrain_page(info)
func _process(delta):
 time_+=delta
 if is_instance_valid(preview_actor):
  preview_actor.rotation.y=lerp_angle(preview_actor.rotation.y,model_yaw,minf(1,delta*8))
  Art.animate(preview_actor,time_,false)
func _unhandled_input(event):
 if event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE,KEY_I]: leave()
func leave():
 State.save_game()
 get_tree().change_scene_to_file(State.travel_scene())

func paragraph(parent: Node, text: String):
 var label=UI.label(parent,text)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.custom_minimum_size=Vector2(300,0)
func build_shop():
 var left=content_panel(Vector2(20,0),Vector2(390,565))
 UI.label(left,"WILLOWBROOK OUTFITTER").add_theme_font_size_override("font_size",23)
 paragraph(left,"Buy a weapon to start fighting. Armor and speaking to Mira are optional. Weapon access combines your primary and both secondary classes.")
 shop_preview=WeaponPreview.new()
 left.add_child(shop_preview)
 shop_info=UI.label(left,"Hover over a weapon to preview it · keyboard focus also works")
 UI.label(left,"Gold: %s · funds reserved only for your first weapon" % State.hero.gold)

 UI.button(left,"View equipped gear",func(): show_page("equipment"))
 UI.button(left,"Return to village",leave)
 var right=content_panel(Vector2(430,0),Vector2(830,565))
 UI.label(right,"BUY & EQUIP · owned items remain in your inventory")
 for name_ in State.equipment_data:
  var item: String=name_
  var entry: Dictionary=State.equipment_data[item]
  if entry.slot=="Any" or item=="Sunsteel Sword": continue
  var owned=State.owns(item)
  var compatible=State.compatible(item)
  var button=UI.button(right,"%s · %s%s\n%s" % [item,"OWNED / EQUIP" if owned else "%d gold" % int(entry.price)," · incompatible" if not compatible else "",GameRules.summary(entry,true)],func():
   if State.owns(item) or State.buy(item): State.equip(entry.slot,item)
   show_page("shop"))
  button.disabled=not compatible or (not owned and not State.can_buy(item))
  button.tooltip_text=entry.description+" · "+entry.rarity
  if entry.slot!="Any":
   button.mouse_entered.connect(func(): preview_shop_weapon(item))
   button.focus_entered.connect(func(): preview_shop_weapon(item))
 for id in InventoryBook.data:
  var supply:String=id
  var entry:Dictionary=InventoryBook.data[id]
  var button=UI.button(right,"%s · %s gold · %s owned\n%s" % [entry.name,entry.price,State.item_count(id),entry.description],func():
   State.buy_supply(supply)
   show_page("shop"))
  button.disabled=State.hero.gold<int(entry.price)+State.weapon_reserve()
  button.mouse_entered.connect(func(): preview_supply(supply))
  button.focus_entered.connect(func(): preview_supply(supply))
 if State.hero.equipment.Weapon!="None": preview_shop_weapon(State.hero.equipment.Weapon)
 else:
  for item in State.equipment_data:
   if State.equipment_data[item].slot=="Weapon" and State.compatible(item):
    preview_shop_weapon(item)
    break
func preview_shop_weapon(item: String):
 if not is_instance_valid(shop_preview): return
 shop_preview.show_item(item)
 var entry: Dictionary=State.equipment_data[item]
 var sources:Array=[]
 for class_ in State.active_classes():
  if State.classes[class_].proficiencies.has(entry.get("weapon_type","")): sources.append(class_)
 var access="Usable through: "+", ".join(sources) if not sources.is_empty() else ("Compatible armor" if State.compatible(item) else "Not usable by your class combination")
 shop_info.text="%s · %s gold\n%s\n%s%s" % [item,int(entry.price),GameRules.summary(entry,true),access,"\nTWO HANDED · shield is stowed" if GameRules.two_handed(entry) else ""]
func preview_supply(id: String):
 shop_preview.show_item(id)
 shop_info.text=InventoryBook.data[id].name+"\n"+InventoryBook.data[id].description
func build_inventory():
 var left=content_panel(Vector2(20,0),Vector2(590,565))
 UI.label(left,"TRAVEL SATCHEL").add_theme_font_size_override("font_size",28)
 var stats=State.stats()
 paragraph(left,"HP %s / %s · MP %s / %s\nCompanion: %s\nUse supplies freely outside battle. Nothing is spent when the target is already full." % [State.hero.hp,stats.max_hp,State.hero.mp,stats.max_mp,State.companion_name()])
 for id in InventoryBook.data:
  var item_id:String=id
  var entry:Dictionary=InventoryBook.data[id]
  paragraph(left,entry.description)
  UI.button(left,"Use %s · %s owned" % [entry.name,State.item_count(id)],func():
   if State.use_item(item_id): Sound.cue("heal")
   show_page("inventory")).disabled=not State.can_use_item(id)
 var right=content_panel(Vector2(630,0),Vector2(630,565))
 UI.label(right,"OWNED EQUIPMENT")
 for item in State.equipment_data:
  if State.owns(item): paragraph(right,item+" · "+State.equipment_data[item].slot)
 UI.button(right,"Equip and inspect gear",func(): show_page("equipment"))
 paragraph(right,"Your classes: %s / %s / %s\nRoles locked until a later chapter.\nBase stats: 60%% primary + 20%% from each secondary, including level growth." % [State.hero.primary,State.hero.secondary[0],State.hero.secondary[1]])
func build_weapons():
 var heading=content_panel(Vector2(20,0),Vector2(1240,82))
 var row=HBoxContainer.new()
 heading.add_child(row)
 var picker=OptionButton.new()
 picker.custom_minimum_size=Vector2(245,38)
 for family in State.weapon_trees: picker.add_item(family.capitalize())
 picker.select(State.weapon_trees.keys().find(weapon_family))
 picker.item_selected.connect(func(index):
  weapon_family=State.weapon_trees.keys()[index]
  weapon_node=State.weapon_trees[weapon_family][0].id
  show_page("weapons"))
 row.add_child(picker)
 UI.label(row,"%s mastery: %s victories · %s skill points" % [weapon_family.capitalize(),State.hero.weapon_mastery[weapon_family],State.hero.points]).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 UI.label(heading,"50 points per full tree · 2 shared points per level · final node requires level 50")
 graph=SkillGraph.new()
 graph.position=Vector2(25,90)
 graph.size=Vector2(845,470)
 body.add_child(graph)
 graph.configure_weapon(weapon_family)
 if not graph.buttons.has(weapon_node): weapon_node=State.weapon_trees[weapon_family][0].id
 graph.selected_id=weapon_node
 graph.selected.connect(func(id): weapon_node=id; refresh_weapon_info())
 info=content_panel(Vector2(895,90),Vector2(365,470))
 refresh_weapon_info()
func refresh_weapon_info():
 for child in info.get_children():
  info.remove_child(child)
  child.queue_free()
 var node: Dictionary={}
 for candidate in State.weapon_trees[weapon_family]:
  if candidate.id==weapon_node: node=candidate
 UI.label(info,weapon_family.to_upper()+" / "+node.name)
 paragraph(info,node.description)
 var learned=State.hero.weapon_skills[weapon_family].has(node.id)
 var missing: Array=[]
 for prerequisite in node.prerequisites:
  if not State.hero.weapon_skills[weapon_family].has(prerequisite): missing.append(prerequisite)
 paragraph(info,"Hero level %s / %s required\nWeapon mastery %s / %s required\nCost %s SP · available %s\n%s" % [State.hero.level,int(node.level_required),State.hero.weapon_mastery[weapon_family],int(node.requires),int(node.cost),State.hero.points,"Prerequisites: "+", ".join(missing) if not missing.is_empty() else "Prerequisites met"])
 var button=UI.button(info,"Learn technique" if not learned else "Already learned",func():
  State.learn_weapon(weapon_family,weapon_node)
  show_page("weapons"))
 button.disabled=learned or not missing.is_empty() or State.hero.level<int(node.level_required) or State.hero.weapon_mastery[weapon_family]<int(node.requires) or State.hero.points<int(node.cost) or not State.proficiencies().has(weapon_family)
 paragraph(info,"Requires proficiency from an equipped class. Learned bonuses apply only while using this weapon family. Shield bonuses require an equipped shield.")
 paragraph(info,"Guardian of the Wild: Paladin + Ranger + Druid. Block to empower your next Mark or Regrowth.")
 constrain_page(info)
func build_companions():
 var left=content_panel(Vector2(20,0),Vector2(390,565))
 UI.label(left,"COMPANION BOND").add_theme_font_size_override("font_size",25)
 if not pending_companion.is_empty():
  paragraph(left,"PERMANENT CHOICE: "+State.companions[pending_companion].name+". You cannot replace this companion with an unchosen one later.")
  UI.button(left,"Confirm permanent bond",func():
   State.choose_companion(pending_companion)
   pending_companion=""
   show_page("companions"))
  UI.button(left,"Cancel choice",func(): pending_companion=""; show_page("companions"))
 if not State.hero.companion.owned.is_empty() and State.hero.journey.finished:
  paragraph(left,"THE BELL BENEATH THE WOODS\nAdventure complete. Your permanent companion is ready for the next road.")
  UI.button(left,"Explore the postgame",leave)
  UI.button(left,"Save & return to title",func():
   State.save_game()
   get_tree().change_scene_to_file("res://scenes/title.tscn"))
 paragraph(left,"One active companion. Your first permanent choice follows the introductory quest; a second choice unlocks after the optional postgame Warden echo. Maximum two owned companions, forever. The temporary wolf is a loan, not a permanent choice.")
 UI.label(left,"Active: "+State.companion_name())
 UI.label(left,"Behavior: "+State.hero.companion.behavior)
 for behavior in ["Attack","Support","Defend"]:
  var selected: String=behavior
  UI.button(left,behavior,func():
   State.hero.companion.behavior=selected
   State.save_game()
   show_page("companions"))
 paragraph(left,"Travel blessing: +25% movement speed with every permanent companion. All main quest routes are accessible to every companion.")
 var right=content_panel(Vector2(430,0),Vector2(830,565))
 var preview_id=pending_companion if not pending_companion.is_empty() else State.hero.companion.current
 companion_preview(right,preview_id)
 var record=State.companion_record()
 if not record.is_empty():
  UI.label(right,"%s · Level %s · XP %s/%s · HP %s/%s · %s bond points" % [State.companion_name(),record.level,record.xp,int(record.level)*60,record.hp,State.companion_max_hp(),record.points])
  for branch in State.companions[State.hero.companion.current].branches:
   var id: String=branch.id
   var trained=record.skills.has(id)
   UI.button(right,"%s · %s
%s" % [branch.name,"LEARNED" if trained else "1 bond point",branch.description],func(): State.train_companion(id); show_page("companions")).disabled=trained or record.points<1
 UI.label(right,"THE SIX BONDS")
 for id in State.companions:
  var selected: String=id
  var entry: Dictionary=State.companions[id]
  var owned=State.hero.companion.owned.has(id)
  var limit=2 if State.hero.companion.postgame_unlocked else 1
  var button=UI.button(right,"%s · %s
%s · travel +25%%" % [entry.name,"OWNED / ACTIVATE" if owned else "Choose permanently",entry.role],func():
   if State.hero.companion.owned.has(selected): State.activate_companion(selected)
   else: pending_companion=selected
   show_page("companions"))
  button.disabled=not owned and (not State.hero.journey.finished or State.hero.companion.owned.size()>=limit)
func build_journal():
 var left=content_panel(Vector2(20,0),Vector2(590,565))
 UI.label(left,"THE BELL BENEATH THE WOODS").add_theme_font_size_override("font_size",23)
 var journey=State.hero.journey
 var steps=[
  [State.starter_ready(),"Buy a weapon at the outfitter"],
  [journey.started,"Speak to Mira beside the camp"],
  [State.hero.exploration.herbs.size()==3,"Gather Moonleaf along Whisperwood and Sunmeadow road"],
  [State.hero.exploration.quest_done,"Return the Moonleaf to Mira"],
  [journey.seals.size()==2,"Cleanse both sanctuary root seals"],
  [journey.boss,"Defeat the Hollow Warden; Defend its charged blow"],
  [journey.finished,"Return the living ember to Mira"],
  [not State.hero.companion.owned.is_empty(),"Choose your first permanent companion"]]
 for step in steps: paragraph(left,("✓ " if step[0] else "○ ")+step[1])
 paragraph(left,"Optional: unlock species mastery, train your companion, improve equipment, and challenge the postgame Warden echo from the village board.")
 for id in QuestBook.data:
  var quest:Dictionary=QuestBook.data[id]
  paragraph(left,"%s · %s/%s%s\n%s" % [quest.name,QuestBook.progress(State.hero,id),quest.goal," · CLAIMED" if State.hero.side_quests.claimed.has(id) else (" · ACTIVE" if State.hero.side_quests.started.has(id) else " · speak to "+quest.giver),quest.description])
 UI.label(left,"Recorded exploration time: %s minutes" % (int(State.hero.demo.elapsed)/60))
 var right=content_panel(Vector2(630,0),Vector2(630,565))
 UI.label(right,"FIELD GUIDE & INVENTORY").add_theme_font_size_override("font_size",24)
 for species in ["goblin","bristleback","mossling"]:
  var wins=int(State.hero.monsters.get(species,0))
  if species=="goblin": wins=maxi(wins,int(State.hero.mastery))
  paragraph(right,"%s · %s / 10 normal victories
%s" % [{"goblin":"Forest Goblin","bristleback":"Meadow Bristleback","mossling":"Briar Mossling"}[species],wins,("AUTO-BATTLE UNLOCKED" if wins>=10 else "Normal victories unlock optional Auto-Battle.") if species!="warden" else "The Hollow Warden must be faced normally."])
 UI.label(right,"Potions: %s · restore 45 HP" % State.hero.potions)
 UI.button(right,"Use a potion",func(): State.use_item("potion"); show_page("journal")).disabled=not State.can_use_item("potion")
 paragraph(right,"Rest at the village camp to restore HP, MP and companion HP. Save at any time outside battle. If defeated, you return to camp without rewards.")
 paragraph(right,"Owned equipment: "+", ".join(State.hero.inventory))

func companion_preview(parent: Node, id: String):
 UI.label(parent,"PREVIEW / "+State.companions.get(id,{"name":"Temporary quest wolf"}).name)
 var container=SubViewportContainer.new()
 container.custom_minimum_size=Vector2(400,245)
 container.stretch=true
 parent.add_child(container)
 var viewport=SubViewport.new()
 viewport.size=Vector2i(780,245)
 viewport.own_world_3d=true
 container.add_child(viewport)
 var root=Node3D.new()
 viewport.add_child(root)
 Art.studio(root)
 preview_actor=CompanionVisual.build(id)
 root.add_child(preview_actor)
 model_yaw=PI+1.2
 preview_actor.rotation.y=model_yaw
 var camera=Camera3D.new()
 root.add_child(camera)
 camera.fov=40
 camera.position=Vector3(2.3,2.0,4.3)
 camera.look_at(Vector3(0,1.15,0))
 camera.current=true

func constrain_page(root: Node):
 for child in root.get_children():
  if child is Label: child.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  if child is Button and child.get_parent() is VBoxContainer:
   child.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
   if child.tooltip_text.is_empty(): child.tooltip_text=child.text
  if not child is SubViewport: constrain_page(child)

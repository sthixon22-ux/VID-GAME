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
 Art.environment_(preview_root)
 preview_actor=Art.actor("Hero",State.hero.equipment)
 preview_root.add_child(preview_actor)
 preview_actor.rotation.y=model_yaw
 var camera=Camera3D.new()
 preview_root.add_child(camera)
 camera.position=Vector3(0,1.3,3.2)
 camera.look_at(Vector3(0,1.05,0))
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
  button.tooltip_text="Change visible gear and derived stats."
  button.disabled=item!="None" and not State.compatible(item)
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
 var switch_button=UI.button(info,"Make %s primary" % selected_class,func():
  State.set_primary(selected_class)
  show_page("skills"))
 switch_button.disabled=not State.can_change_class() or State.hero.primary==selected_class
 for entry in [["secondary_1","Secondary 1"],["secondary_2","Secondary 2"]]:
  var slot_id: String=entry[0]
  UI.button(info,"Assign to "+entry[1],func():
   State.set_class_slot(slot_id,selected_class)
   show_page("skills")).disabled=not State.can_change_class()
 UI.label(info,"Each full tree costs 50 SP; capstone at level 50.\nEarn 2 shared SP per level.\nChange classes at the village camp.
Starting abilities remain available.\nGold nodes are learned.\nLines show the required path.")
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
 paragraph(left,"Buy compatible gear before taking the northern trail. Your three classes grant weapon proficiencies; your primary class controls heavy armor. Monk-trained heroes may fight unarmed. Shields are optional. Purchases are permanent and equipping costs nothing.")
 paragraph(left,"120-gold starter budget.\nPick a compatible weapon and chest armor.\nLeather 25 / Robe 35 / Plate 45.\nPlate: Warrior or Paladin primary.\n\nYour proficiencies: "+", ".join(State.proficiencies()))
 UI.label(left,"Gold available: %s" % State.hero.gold)
 UI.label(left,"Starter funds are reserved until each essential slot is owned.")
 UI.button(left,"Potion · 8 gold",func():
  State.buy_potion()
  show_page("shop")).disabled=State.hero.gold<8 or (State.hero.profile.economy and not State.starter_ready())
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
  [State.starter_ready(),"Buy and equip a compatible starter kit at the outfitter"],
  [journey.started,"Speak to Mira beside the camp"],
  [State.hero.exploration.herbs.size()==3,"Gather three Moonleaf sprigs along the northern trail"],
  [State.hero.exploration.quest_done,"Return the Moonleaf to Mira"],
  [journey.seals.size()==2,"Cleanse both sanctuary root seals"],
  [journey.boss,"Defeat the Hollow Warden; Defend its charged blow"],
  [journey.finished,"Return the living ember to Mira"],
  [not State.hero.companion.owned.is_empty(),"Choose your first permanent companion"]]
 for step in steps: paragraph(left,("✓ " if step[0] else "○ ")+step[1])
 paragraph(left,"Optional: unlock species mastery, train your companion, improve equipment, and challenge the postgame Warden echo from the village board.")
 UI.label(left,"Recorded exploration time: %s minutes" % (int(State.hero.demo.elapsed)/60))
 var right=content_panel(Vector2(630,0),Vector2(630,565))
 UI.label(right,"FIELD GUIDE & INVENTORY").add_theme_font_size_override("font_size",24)
 for species in ["goblin","mossling"]:
  var wins=int(State.hero.monsters.get(species,0))
  if species=="goblin": wins=maxi(wins,int(State.hero.mastery))
  paragraph(right,"%s · %s / 10 normal victories
%s" % ["Forest Goblin" if species=="goblin" else "Briar Mossling",wins,("AUTO-BATTLE UNLOCKED" if wins>=10 else "Normal victories unlock optional Auto-Battle.") if species=="goblin" else "Story guardians: counted in your journal, excluded from Auto-Battle."])
 UI.label(right,"Potions: %s · restore 45 HP" % State.hero.potions)
 UI.button(right,"Use a potion",func(): State.use_potion(); show_page("journal")).disabled=State.hero.potions<=0 or State.hero.hp>=State.stats().max_hp
 paragraph(right,"Rest at the village camp to restore HP, MP and companion HP. Save at any time outside battle. If defeated, you return to camp without rewards.")
 paragraph(right,"Owned equipment: "+", ".join(State.hero.inventory))

func companion_preview(parent: Node, id: String):
 UI.label(parent,"PREVIEW / "+State.companions.get(id,{"name":"Temporary quest wolf"}).name)
 var container=SubViewportContainer.new()
 container.custom_minimum_size=Vector2(400,195)
 container.stretch=true
 parent.add_child(container)
 var viewport=SubViewport.new()
 viewport.size=Vector2i(780,195)
 viewport.own_world_3d=true
 container.add_child(viewport)
 var root=Node3D.new()
 viewport.add_child(root)
 Art.environment_(root)
 preview_actor=CompanionVisual.build(id)
 root.add_child(preview_actor)
 model_yaw=0.45
 preview_actor.rotation.y=model_yaw
 var camera=Camera3D.new()
 root.add_child(camera)
 camera.fov=40
 camera.position=Vector3(1.8,1.9,3.8)
 camera.look_at(Vector3(0,1,0))
 camera.current=true

func constrain_page(root: Node):
 for child in root.get_children():
  if child is Label: child.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  if child is Button and child.get_parent() is VBoxContainer:
   child.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
   if child.tooltip_text.is_empty(): child.tooltip_text=child.text
  if not child is SubViewport: constrain_page(child)

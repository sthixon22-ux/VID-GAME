extends Node
var failures=0
var checks=0
func check(value: bool, label: String):
 checks+=1
 if value: print("PASS: ",label)
 else:
  failures+=1
  push_error(label)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func run():
 Engine.time_scale=8
 State.reset()
 State.hero.points=20
 check(not State.invest_skill("Paladin","mythic") and State.hero.points==20,"Mythic prerequisites cannot be bypassed")
 check(State.invest_skill("Paladin","oath"),"Root node learns with one point")
 var attack=State.stats().attack
 check(attack==25,"Learned attack node changes derived stats")
 check(not State.invest_skill("Paladin","oath") and State.hero.points==19,"Duplicate investment rejected")
 check(not State.invest_skill("Paladin","shield"),"Level-one hero cannot buy level-five branch")
 State.hero.level=50
 State.hero.class_mastery.Paladin=100
 State.hero.points=99
 check(State.invest_skill("Paladin","shield"),"Eligible first branch can be learned")
 check(not State.invest_skill("Paladin","mythic"),"Mythic still requires its entire prerequisite path")
 for node in State.classes.Paladin.nodes:
  if node.id not in ["oath","shield","mythic"]: State.invest_skill("Paladin",node.id)
 check(State.invest_skill("Paladin","mythic"),"Level-50 prerequisite path unlocks mythic")
 check(State.hero.points==50 and State.can_mythic("Paladin"),"Full tree costs fifty points and primary mythic activates")
 State.set_primary("Ranger")
 check(not State.can_mythic("Paladin") and State.hero.skills.Paladin.has("mythic"),"Switching primary preserves but disables secondary mythic")
 State.set_primary("Paladin")
 State.save_game()
 var skills=State.hero.skills.duplicate(true)
 State.reset()
 State.load_game()
 check(State.hero.skills==skills,"Branched skills persist")
 var legacy=State.hero.duplicate(true)
 legacy.erase("skills")
 legacy.erase("progression_version")
 legacy.investments.Druid=3
 legacy.equipment.Helmet="Leather Gear"
 var file=FileAccess.open(State.SAVE,FileAccess.WRITE)
 file.store_string(JSON.stringify(legacy))
 file.close()
 State.reset()
 State.load_game()
 check(State.hero.skills.Druid.is_empty() and State.hero.progression_archive.skills.Druid.has("mythic") and State.hero.points==100,"Legacy skills are archived and respecced into the new point budget")
 check(State.hero.equipment.Helmet=="Ranger Hood","Legacy generic armor migrates to visible slot-specific gear")
 State.reset()
 check(not State.equip("Helmet","Sunsteel Sword"),"Wrong-slot equipment rejected")
 var items={"Weapon":"Moonleaf Saber","Shield":"Dawn Kite Shield","Helmet":"Steel Helm","Chest":"Verdant Robe","Gauntlets":"Steel Gauntlets","Pants":"Steel Greaves","Boots":"Steel Sabatons","Accessory":"Sunstone Pendant"}
 for slot in items: check(State.equip(slot,items[slot]),"Equip independent slot: "+slot)
 var hero=Art.actor("Hero",State.hero.equipment)
 add_child(hero)
 check(hero.model.name=="Mage","Robe uses a designed, rigged outfit mesh")
 check(hero.skeleton.get_bone_count()>30,"Hero has a real articulated skeleton")
 check(hero.find_child("EquippedWeapon",true,false)!=null and hero.find_child("EquippedShield",true,false)!=null,"Weapons and shield are attached to the rig")
 check(hero.find_child("EquippedHelmet",true,false)!=null,"Helmet appears independently of robe")
 for slot in ["Gauntlets","Pants","Boots","Accessory"]:
  check(not hero.find_children("Equipped"+slot+"*","MeshInstance3D",true,false).is_empty(),"Visible modular piece: "+slot)
 var clips: Array=[]
 var actions=["Attack","Sword Slash","Shield Bash","Sacred Strike","Hunter's Mark","Thornbind","Regrowth","Dawn Avatar","Wild Hunt","Ancient Grove"]
 for action in actions:
  var clip=HeroVisual.ACTION_CLIPS[action]
  check(hero.player.has_animation(clip) and not clips.has(clip),"Distinct imported skeleton clip: "+action)
  clips.append(clip)
  hero.play_action(action)
  hero.player.advance(0.25)
  check(hero.last_action==action and hero.player.is_playing(),"Animation executes: "+action)
 hero.action_remaining=0
 hero.motion(true,true)
 check(hero.player.current_animation=="Running_A","Exploration uses a real run animation")
 for chest in ["Steel Cuirass","Leather Vest"]:
  State.equip("Chest",chest)
  var outfit=Art.actor("Hero",State.hero.equipment)
  add_child(outfit)
  check(outfit.model.name==("Knight" if chest=="Steel Cuirass" else "Rogue"),"Outfit changes full silhouette: "+chest)
  outfit.queue_free()
 State.equip("Helmet","Ranger Hood")
 var hooded=Art.actor("Hero",State.hero.equipment)
 add_child(hooded)
 check(hooded.find_child("EquippedHelmet",true,false).get_aabb().size.x>1,"Ranger hood has a full-size open-face mesh")
 hooded.queue_free()
 hero.queue_free()
 State.reset()
 State.menu_page="skills"
 get_tree().change_scene_to_file("res://scenes/character.tscn")
 await get_tree().process_frame
 await get_tree().process_frame
 var menu=get_tree().current_scene
 check(menu.graph.buttons.size()==12,"Dedicated page shows twelve connected skill nodes")
 menu.graph.buttons.oath.pressed.emit()
 var learn=find_button(menu.info,"Learn skill")
 check(learn!=null and not learn.disabled,"Root node has an enabled Learn button")
 learn.pressed.emit()
 check(State.hero.skills.Paladin.has("oath") and State.hero.points==1,"UI investment spends exactly one point")
 menu.graph.buttons.mythic.pressed.emit()
 learn=find_button(menu.info,"Learn skill")
 check(learn.disabled,"UI prevents learning locked mythic")
 menu.show_page("equipment")
 check(is_instance_valid(menu.preview_actor),"Equipment page has a live 3D preview")
 menu.slot="Chest"
 menu.show_page("equipment")
 var robe=find_button(menu.body,"Verdant Robe",true)
 robe.pressed.emit()
 check(State.hero.equipment.Chest=="Verdant Robe" and menu.preview_actor.model.name=="Mage","Equipment button updates state and visible 3D outfit")
 menu.slot="Helmet"
 menu.show_page("equipment")
 find_button(menu.body,"Steel Helm",true).pressed.emit()
 check(menu.preview_actor.find_child("EquippedHelmet",true,false)!=null,"Helmet button updates preview")
 # Exercise all spell VFX and cleanup under the engine.
 var host=Node3D.new()
 add_child(host)
 hero=Art.actor("Hero",State.hero.equipment)
 host.add_child(hero)
 var target=Art.actor("Warden")
 host.add_child(target)
 target.position=Vector3(3,0,0)
 for action in actions:
  await BattleMotion.present(host,hero,hero if action in ["Regrowth","Ancient Grove"] else target,action)
  await get_tree().create_timer(1.3).timeout
 check(host.get_child_count()==2,"All action VFX finish and clean up")
 host.queue_free()
 State.reset()
 State.save_game()
 await get_tree().process_frame
 print("Presentation checks: ",checks," Failures: ",failures)
 get_tree().quit(1 if failures else 0)
func find_button(node: Node, text_: String, contains=false) -> Button:
 for button in node.find_children("*","Button",true,false):
  if button.text==text_ or (contains and button.text.contains(text_)): return button
 return null

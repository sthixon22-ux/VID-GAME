extends Node
var checks=0
var failures=0
func check(value: bool, description: String):
 checks+=1
 if value: print("PASS: ",description)
 else:
  failures+=1
  push_error(description)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func settle():
 for i in range(8): await get_tree().process_frame
func run():
 State.new_adventure()
 State.create_hero("Preview","Paladin",0,0,0,["Ranger","Druid"])
 var world=load("res://scenes/world.tscn").instantiate()
 check(not world.ready_for_trail(),"No weapon blocks combat")
 check(State.buy("Oak Staff"),"Buy a secondary-class weapon")
 check(not State.hero.journey.started and State.hero.equipment.Chest=="None","No conversation or armor in this test")
 check(world.ready_for_trail(),"Owning a weapon unlocks combat before Mira and armor, even while unequipped")
 check(State.equip("Weapon","Oak Staff"),"Secondary Druid grants staff equipment")
 State.hero.hp=0
 check(not world.ready_for_trail(),"Defeated hero still needs recovery")
 State.restore()
 world.free()
 await settle()
 # Cover every proficiency in either secondary slot through the same equip API the shop uses.
 for class_ in State.classes:
  if class_=="Paladin": continue
  for index in range(2):
   var secondaries:Array=["Paladin","Paladin"]
   secondaries[index]=class_
   secondaries[1-index]="Ranger" if class_!="Ranger" else "Druid"
   State.hero.primary="Paladin"
   State.hero.secondary=secondaries
   for item in State.equipment_data:
    var entry:Dictionary=State.equipment_data[item]
    if entry.slot!="Weapon" or not State.classes[class_].proficiencies.has(entry.weapon_type): continue
    State.grant_item(item)
    check(State.compatible(item) and State.equip("Weapon",item),"%s secondary slot %s grants %s" % [class_,index+1,item])
 State.new_adventure()
 State.create_hero("Preview","Paladin",0,0,0,["Ranger","Druid"])
 State.menu_page="shop"
 var menu=load("res://scenes/character.tscn").instantiate()
 get_tree().root.add_child(menu)
 await settle()
 var before=State.hero.duplicate(true)
 for item in State.equipment_data:
  if State.equipment_data[item].slot!="Weapon": continue
  menu.preview_shop_weapon(item)
  check(menu.shop_preview.item_name==item and menu.shop_preview.pivot.get_child_count()==1,"3D preview exists for "+item)
 check(State.hero==before,"Previewing all weapons does not buy, equip, spend gold or mutate hero")
 var hovered:Button
 var pending:Array[Node]=[menu.body]
 while not pending.is_empty():
  var node=pending.pop_back()
  if node is Button and node.text.begins_with("Iron Sword"):
   hovered=node
   break
  for child in node.get_children(): pending.append(child)
 check(hovered!=null,"Shop exposes weapon buttons")
 if hovered:
  hovered.mouse_entered.emit()
  check(menu.shop_preview.item_name=="Iron Sword","Hover signal updates preview")
  hovered.focus_entered.emit()
  check(menu.shop_info.text.contains("Paladin"),"Keyboard preview identifies class granting access")
 menu.preview_shop_weapon("Oak Staff")
 await settle()
 if DisplayServer.get_name()!="headless" and not OS.get_cmdline_user_args().is_empty():
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
 print("Shop flow checks: %s Failures: %s" % [checks,failures])
 await Sound.stop_all()
 menu.queue_free()
 await settle()
 get_tree().quit.call_deferred(1 if failures else 0)

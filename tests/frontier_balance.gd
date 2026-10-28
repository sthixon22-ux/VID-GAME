extends Node
func _ready():call_deferred("run")
func run():
 var state=get_tree().root.get_node("State")
 var names=state.classes.keys()
 var failures=0
 var checks=0
 for region in ["sahir","kharholt"]:
  for i in names.size():
   state.new_adventure();state.create_hero("Trial",names[i],0,0,0,[names[(i+1)%12],names[(i+2)%12]],"Female")
   state.hero.level=8 if region=="sahir" else 12
   state.hero.journey.finished=true;state.choose_companion("dire_wolf")
   var weapon=""
   for item in ShopBook.stock(region+"_weapons"):
    if state.compatible(item):weapon=item;break
   state.grant_item(weapon);state.equip("Weapon",weapon)
   var armor="Sunveil Coat" if region=="sahir" else "Forgeguard Coat"
   state.grant_item(armor);state.equip("Chest",armor)
   state.hero.potions=6;state.restore()
   var sim=Combat.new(state.hero,state.stats(),ExpeditionRules.regions[region].boss)
   sim.auto_resolve()
   checks+=1
   if sim.outcome!="Victory" or weapon.is_empty():failures+=1
   print("BALANCE ",region," ",names[i]," ",weapon," ",sim.outcome," rounds ",sim.turns," HP ",sim.h.hp," potions ",sim.h.potions)
 print("Balance checks: %s Failures: %s" % [checks,failures])
 get_tree().quit(1 if failures else 0)

extends Node
var checks=0
var failures=0
func check(value:bool,label:String):
 checks+=1
 if value:print("PASS: ",label)
 else:failures+=1;push_error(label)
func prepare(primary="Paladin",secondary:Array=[]):
 State.new_adventure()
 State.create_hero("Progression",primary,0,0,0,secondary)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func run():
 check(ShopBook.stock()==["Iron Sword","Twin Daggers","Oak Staff","Traveler's Clothing","Traveler's Pendant"],"Starter outfitter has exactly five equipment choices")
 prepare()
 var gold=State.hero.gold
 check(not State.buy("Sunsteel Sword") and State.hero.gold==gold,"Future equipment is not purchasable at the starter shop")
 var coverage=true
 var combinations=0
 for primary in State.classes:
  for second in State.classes:
   if second==primary:continue
   for third in State.classes:
    if third in [primary,second]:continue
    State.hero.primary=primary
    State.hero.secondary=[second,third]
    var has_weapon=false
    for item in ShopBook.stock():
     if State.equipment_data[item].slot=="Weapon" and State.compatible(item):has_weapon=true
    coverage=coverage and has_weapon
    combinations+=1
 check(coverage and combinations==1320,"Three starter weapons cover all 1320 valid class-role combinations")
 prepare()
 State.hero.points=60
 var before=State.stats()
 var all_learned=true
 for node in State.classes.Paladin.nodes:all_learned=State.invest_skill("Paladin",node.id) and all_learned
 check(all_learned and State.hero.level==1 and State.hero.points==0,"Sixty banked points complete a whole class tree at level one")
 check(not State.learn_weapon("sword","edge"),"Spending the shared budget prevents another tree investment")
 State.hero.primary="Wizard"
 State.hero.secondary=["Sorcerer","Necromancer"]
 var baseline=GameRules.combined_stats(State.classes,"Wizard",State.hero.secondary,1)
 var permanent=State.stats()
 check(permanent.max_hp>baseline.max_hp and permanent.defense>baseline.defense,"Paladin passives remain after all three class roles change")
 check(not State.can_mythic("Paladin"),"Permanent stats do not bypass primary-only mythic restriction")
 prepare("Wizard",["Sorcerer","Necromancer"])
 State.grant_item("Iron Sword")
 check(not State.equip("Weapon","Iron Sword"),"Caster combination cannot equip a sword before Freedom")
 State.hero.points=58
 for node in State.weapon_trees.sword:State.learn_weapon("sword",node.id)
 check(not State.hero.weapon_skills.sword.has("master") and not State.equip("Weapon","Iron Sword"),"Level-29 lifetime budget of 58 cannot finish sword tree")
 State.hero.points+=2
 check(State.learn_weapon("sword","master") and State.hero.points==0 and State.equip("Weapon","Iron Sword"),"Sixty-point Sword Freedom permits equipping independently of class")
 check(Combat.new(State.hero,State.stats()).legal("sword_slash"),"Freedom also enables equipped sword actions")
 State.save_game()
 State.reset()
 State.load_game()
 check(State.hero.weapon_skills.sword.has("master") and State.compatible("Iron Sword"),"Permanent weapon proficiency survives save/load")
 prepare()
 State.grant_item("Iron Sword")
 State.equip("Weapon","Iron Sword")
 check(not Combat.new(State.hero,State.stats()).legal("paladin_adept") and not Combat.new(State.hero,State.stats()).legal("sword_master_technique"),"Learned combat arts are unavailable before their nodes")
 State.hero.points=120
 for node in State.classes.Paladin.nodes:State.invest_skill("Paladin",node.id)
 for node in State.weapon_trees.sword:State.learn_weapon("sword",node.id)
 State.hero.hp=10
 State.restore()
 State.hero.hp=10
 var sim=Combat.new(State.hero,State.stats())
 var mana=sim.h.mp
 sim.round_("paladin_adept")
 check(sim.h.hp>10 and sim.h.mp==mana-7,"Holy Light actually heals and consumes seven MP")
 sim=Combat.new(State.hero,State.stats())
 mana=sim.h.mp
 var events=sim.round_("sword_master_technique")
 check(sim.h.mp==mana-8 and events.any(func(event):return event.text.begins_with("Thunder Strike")),"Thunder Strike is a real MP-consuming learned weapon attack")
 var expected={"dragon":{"max_mp":12,"attack":3},"spirit_fox":{"max_mp":12,"healing":5},"dire_wolf":{"attack":3,"critical":6},"griffin":{"attack":3,"dexterity":6},"golem":{"max_hp":18,"defense":4},"warhorse":{"max_hp":18,"agility":5}}
 for id in State.companions:
  prepare()
  var base=State.stats()
  State.hero.journey.finished=true
  check(State.choose_companion(id),"Permanent bond selected: "+id)
  var attributes=State.stats()
  var valid=true
  for key in expected[id]:valid=valid and attributes[key]==base[key]+expected[id][key]
  check(valid,"Distinct hero stat aura: "+id)
  var record=State.companion_record()
  check(record.points==record.level*2,"Companion earns two independent bond points per level: "+id)
  check(not State.train_companion("capstone"),"Companion capstone requires its branches: "+id)
  record.points=80
  var all_nodes=true
  for node in State.companions[id].nodes:all_nodes=State.train_companion(node.id) and all_nodes
  check(all_nodes and record.points==0 and CompanionRules.learned_abilities(State.hero).size()==3,"Eight-node companion tree costs 80 and teaches three unique arts: "+id)
  State.restore()
  State.hero.hp=1
  State.hero.mp=0
  for art in State.companions[id].abilities:
   var entry=State.companions[id].abilities[art]
   State.hero.companion.behavior=entry.behavior
   sim=Combat.new(State.hero,State.stats())
   sim.enemy_hp=9999
   # Isolate each learned ability to check the automated selector, not a direct bypass.
   sim.h.companion.records[id].skills=[]
   for node in State.companions[id].nodes:
    if node.grants.has(art):sim.h.companion.records[id].skills.append(node.id)
   sim.companion_turn()
   match entry.effect:
    "mana":check(sim.h.mp==entry.power,"Dragon art restores real MP")
    "heal","renewal":check(sim.h.hp>1 and (entry.effect!="renewal" or sim.regeneration==3),"Fox art restores HP and applies learned renewal")
    "buff_attack","buff_defense","buff_agility","buff_dexterity","ward":
     var key="defense" if entry.effect=="ward" else str(entry.effect).trim_prefix("buff_")
     check(sim.current_stat(key)==sim.stats[key]+entry.power,"Learned companion buff changes actual battle stat: "+key)
    "bleed":check(sim.bleed==3 and sim.enemy_hp<9999,"Learned wolf art deals damage and applies bleed")
    "stun":check(sim.enemy_stun==1 and sim.enemy_hp<9999,"Learned companion art damages and stuns")
    _:check(sim.enemy_hp<9999,"Learned companion attack damages enemy")
   check(sim.events.any(func(event):return event.actor=="Wolf" and event.text.begins_with(entry.name)),"Automated learned companion art resolves: "+art)
   check(sim.companion_cooldowns.get(art,0)>0,"Learned companion art enters cooldown: "+art)
   sim.events=[]
   sim.companion_turn()
   check(not sim.events.any(func(event):return event.text.begins_with(entry.name)),"Companion cannot spam an art through cooldown: "+art)
  State.save_game()
  State.reset()
  State.load_game()
  check(State.companion_record().skills.size()==8 and CompanionRules.learned_abilities(State.hero).size()==3,"Companion investments and abilities survive reload: "+id)
  var auto=Combat.new(State.hero,State.stats(),"warden")
  var normal=Combat.new(State.hero,State.stats(),"warden")
  auto.auto_resolve()
  while normal.outcome=="" and normal.turns<200:normal.round_(normal.auto_action())
  check(auto.h==normal.h and auto.enemy_hp==normal.enemy_hp,"Companion arts preserve normal/Auto deterministic parity: "+id)
 prepare()
 State.hero.journey.finished=true
 State.choose_companion("golem")
 State.restore()
 State.hero.companion.postgame_unlocked=true
 State.choose_companion("dragon")
 check(State.hero.hp<=State.stats().max_hp,"Choosing a second companion clamps lost HP capacity")
 State.hero.companion.records.golem.points=80
 check(State.train_companion_for("golem","predator") and State.hero.companion.current=="dragon","Reserve companion training never changes active selection")
 var stats=State.stats()
 stats.critical=100
 stats.dexterity=0
 sim=Combat.new(State.hero,stats)
 var criticals=0
 var damage_correct=true
 for seed_ in range(100):
  sim.rng.seed=seed_
  sim.events=[]
  sim.hit_enemy("Hero",30,"Attack")
  if sim.events[0].text.ends_with("Critical!"):
   criticals+=1
   damage_correct=damage_correct and sim.events[0].amount==ceili(sim.damage(30,int(sim.enemy.defense))*1.5)
 check(damage_correct and criticals>35 and criticals<85,"Critical rolls are capped and increase physical damage by fifty percent")
 State.menu_page="companion_tree"
 get_tree().change_scene_to_file("res://scenes/character.tscn")
 await get_tree().process_frame
 await get_tree().process_frame
 var menu=get_tree().current_scene
 menu.companion_tree_id="dragon"
 menu.companion_skill="predator"
 State.companion_record().points=80
 menu.show_page("companion_tree")
 check(menu.graph.buttons.size()==8,"Companion has a dedicated eight-node skill page")
 var learn:Button=null
 for button in menu.info.find_children("*","Button",true,false):
  if button.text=="Learn companion skill":learn=button
 check(learn!=null and not learn.disabled,"Owned companion root can be trained in the menu")
 learn.pressed.emit()
 check(State.companion_record().skills.has("predator") and State.companion_record().points==77,"Companion tree UI spends the selected companion's bond point")
 menu.show_page("shop")
 var hidden=false
 for button in menu.body.find_children("*","Button",true,false):
  if button.text.contains("Sunsteel") or button.text.contains("Steel Cuirass"):hidden=true
 check(not hidden,"Starter shop menu hides future equipment")
 print("Progression 0.9 checks: %s Failures: %s" % [checks,failures])
 get_tree().quit(1 if failures else 0)

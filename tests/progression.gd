extends Node
var checks=0
var failures=0
func check(value: bool, label: String):
 checks+=1
 if value: print("PASS: ",label)
 else:
  failures+=1
  push_error(label)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func prepare(primary: String, secondary: Array=[]):
 State.new_adventure()
 State.create_hero("Test",primary,0,0,0,secondary)
func raw_save(data: Dictionary):
 var file=FileAccess.open(State.SAVE,FileAccess.WRITE)
 file.store_string(JSON.stringify(data))
 file.close()
func run():
 check(State.classes.size()==12,"All twelve classes are selectable definitions")
 var expected=["Warrior","Barbarian","Paladin","Wizard","Sorcerer","Healer","Ranger","Rogue","Assassin","Monk","Druid","Necromancer"]
 for name_ in expected:
  prepare(name_)
  check(State.hero.primary==name_ and State.hero.secondary.size()==2,"Creation accepts "+name_)
  for id in State.classes[name_].spellbook:
   var ability=AbilityBook.entry(id)
   if not ability.get("weapon_types",[]).is_empty():
    var family: String=ability.weapon_types[0]
    if family=="unarmed": State.hero.equipment.Weapon="None"
    else:
     for item in State.equipment_data:
      if State.equipment_data[item].get("weapon_type","")==family and State.equipment_data[item].slot=="Weapon":
       State.grant_item(item)
       State.equip("Weapon",item)
       break
   State.hero.hp=State.stats().max_hp-15
   State.hero.mp=mini(20,int(State.stats().max_mp))
   var starting=Combat.new(State.hero,State.stats())
   var before_mp=int(starting.h.mp)
   check(starting.legal(id) and not starting.round_(id).is_empty(),"Starting class ability resolves: "+id)
   check(starting.h.mp==before_mp-int(ability.mp) if ability.effect!="meditate" else starting.h.mp>before_mp,"Starting ability mana behavior is correct: "+id)
  State.hero.equipment.Weapon="None"
  var base=State.stats()
  var correct=true
  for key in GameRules.STAT_KEYS:
   if base[key]!=int(GameRules.combined_stats(State.classes,name_,State.hero.secondary,1)[key]): correct=false
  check(correct,"Unequipped baseline blends all three classes: "+name_)
  State.hero.level=50
  var grown=State.stats()
  check(GameRules.STAT_KEYS.all(func(key): return grown[key]>base[key]),"All six stats grow naturally through level fifty: "+name_)
  check(State.classes[name_].nodes.size()==12 and State.classes[name_].nodes.reduce(func(total,node): return total+int(node.cost),0)==50,"Class tree has twelve nodes costing fifty points: "+name_)
  State.hero.level=1
  State.hero.points=999
  State.hero.class_mastery[name_]=999
  State.invest_skill(name_,"oath")
  check(not State.invest_skill(name_,"shield") and not State.invest_skill(name_,"mythic"),"Banked points/mastery cannot bypass hero-level gates: "+name_)
  State.hero.level=49
  for node in State.classes[name_].nodes:
   if node.id!="mythic" and not State.hero.skills[name_].has(node.id): State.invest_skill(name_,node.id)
  check(not State.invest_skill(name_,"mythic"),"Full prerequisite path still cannot finish before level fifty: "+name_)
  State.hero.level=50
  check(State.invest_skill(name_,"mythic") and State.can_mythic(name_),"Level-fifty primary capstone becomes usable: "+name_)
  State.hero.profile.economy=true
  State.restore()
  var sim=Combat.new(State.hero,State.stats())
  check(sim.legal(State.classes[name_].mythic),"Primary mythic has a real usable ability: "+name_)
  sim.round_(State.classes[name_].mythic)
  check(sim.h.mp==State.hero.mp-sim.cost(State.classes[name_].mythic) and not sim.events.is_empty(),"Mythic spends MP and resolves events: "+name_)
  check(not State.set_class_slot("primary",State.hero.secondary[0]),"Primary role is locked after creation: "+name_)
  State.hero.primary=State.hero.secondary[0] # Simulate a future chapter to test mythic availability independently.
  check(State.hero.skills[name_].has("mythic") and not State.can_mythic(name_),"Secondary mythic remains saved but unavailable: "+name_)
 # Each class can afford its own matching kit and complete the existing battle sequence.
 var starters={"Warrior":"Iron Sword","Barbarian":"Iron Axe","Paladin":"Iron Sword","Wizard":"Oak Staff","Sorcerer":"Bone Wand","Healer":"Oak Staff","Ranger":"Woodland Bow","Rogue":"Twin Daggers","Assassin":"Twin Daggers","Monk":"Traveler Claws","Druid":"Oak Staff","Necromancer":"Field Scythe"}
 for class_ in expected:
  prepare(class_)
  var chest="Steel Cuirass" if class_ in ["Warrior","Paladin"] else ("Verdant Robe" if class_ in ["Wizard","Sorcerer","Healer","Druid","Necromancer"] else "Leather Vest")
  var kit_ok=true
  var kit_items=[starters[class_],chest]
  if not GameRules.two_handed(State.equipment_data[starters[class_]]): kit_items.append("Oak Shield")
  for item in kit_items:
   if not State.buy(item) or not State.equip(State.equipment_data[item].slot,item): kit_ok=false
  check(kit_ok and State.starter_ready(),"Matching starter kit is affordable and equippable: "+class_)
  State.restore()
  var battles_ok=true
  for index in range(6):
   if index in [3,5]:
    State.restore()
    State.hero.potions+=3
   var species="goblin" if index<3 else ("mossling" if index<5 else "warden")
   var sim=Combat.new(State.hero,State.stats(),species)
   sim.auto_resolve()
   State.hero=sim.h
   if sim.outcome!="Victory": battles_ok=false; break
   State.reward(true,species)
   if index<3: State.hero.potions+=1
  check(battles_ok,"Class can finish the six-fight introductory sequence: "+class_)
  var model=Art.actor("Hero",State.hero.equipment)
  check(model.find_child("EquippedWeapon",true,false)!=null,"Matching weapon has visible geometry: "+class_)
  model.free()
 # Every distinct three-class permutation produces a legal, unique loadout and stat block.
 prepare("Paladin")
 var combinations=0
 var combos_ok=true
 for primary in expected:
  for secondary1 in expected:
   if secondary1==primary: continue
   for secondary2 in expected:
    if secondary2 in [primary,secondary1]: continue
    State.hero.primary=primary
    State.hero.secondary=[secondary1,secondary2]
    var stats=State.stats()
    if stats.agility<1 or stats.dexterity<0 or State.active_classes().size()!=3: combos_ok=false
    if AbilityBook.available(State.hero).is_empty(): combos_ok=false
    combinations+=1
 check(combos_ok and combinations==1320,"All 1,320 ordered three-class combinations have stats and usable class books")
 # Every weapon tree has a complete, guarded level-50 path, not a two-node demo stub.
 for family in State.weapon_trees:
  prepare("Monk",["Warrior","Necromancer"])
  if family=="hammer": State.hero.secondary=["Barbarian","Necromancer"]
  if family in ["bow","dagger"]: State.hero.secondary=["Ranger","Warrior"]
  var nodes: Array=State.weapon_trees[family]
  check(nodes.size()==12 and nodes.reduce(func(total,node): return total+int(node.cost),0)==50,"Weapon tree totals fifty points: "+family)
  State.hero.points=100
  State.hero.weapon_mastery[family]=100
  var first: String=nodes[0].id
  check(State.learn_weapon(family,first),"Proficient class can learn weapon root: "+family)
  check(not State.learn_weapon(family,nodes[1].id),"Weapon tier cannot be rushed at level one: "+family)
  State.hero.level=49
  for node in nodes:
   if node.id not in [first,"master"]: State.learn_weapon(family,node.id)
  check(not State.learn_weapon(family,"master"),"Weapon capstone is locked before level fifty: "+family)
  State.hero.level=50
  check(State.learn_weapon(family,"master") and State.hero.points==50,"Entire weapon tree costs fifty and completes at fifty: "+family)
 # Advanced weapon actions require the learned tier; direct calls cannot bypass it.
 prepare("Warrior",["Paladin","Druid"])
 State.grant_item("Iron Sword")
 State.equip("Weapon","Iron Sword")
 check(not Combat.new(State.hero,State.stats()).legal("sword_master_technique"),"Hidden advanced weapon actions are illegal before learning their node")
 State.hero.level=50
 State.hero.weapon_mastery.sword=100
 State.hero.points=100
 for node in State.weapon_trees.sword:
  if node.id!="master": State.learn_weapon("sword",node.id)
 check(Combat.new(State.hero,State.stats()).legal("sword_master_technique"),"Learned level-35 weapon tier unlocks its active technique")
 State.equip("Weapon","None")
 check(not Combat.new(State.hero,State.stats()).legal("sword_master_technique"),"Advanced weapon technique disables when the matching weapon is removed")
 prepare("Wizard",["Sorcerer","Necromancer"])
 State.grant_item("Iron Sword")
 check(not State.equip("Weapon","Iron Sword") and not State.learn_weapon("sword","edge"),"Class proficiencies enforce both gear and weapon-tree eligibility")
 check(not State.set_class_slot("secondary_1","Warrior") and not State.equip("Weapon","Iron Sword") and State.hero.secondary==["Sorcerer","Necromancer"],"Secondary roles remain locked and incompatible weapons stay unavailable")
 # Gear bonuses affect the actual six-stat block, not only menu text.
 prepare("Paladin")
 var initial=State.stats()
 for item in ["Trail Boots","Moonleaf Charm","Verdant Robe"]:
  State.grant_item(item)
  State.equip(State.equipment_data[item].slot,item)
 var geared=State.stats()
 check(geared.agility>initial.agility and geared.dexterity>initial.dexterity and geared.max_mp>initial.max_mp,"Armor/accessories change agility, dexterity and MP")
 check(geared.speed==geared.agility,"Legacy speed alias remains identical to agility")
 # Initiative and deterministic evasion.
 prepare("Rogue")
 State.hero.companion.active=false
 State.hero.hp=99999
 var attributes=State.stats()
 attributes.max_hp=99999
 attributes.agility=100
 attributes.dexterity=0
 var fast=Combat.new(State.hero,attributes)
 fast.enemy_hp=99999
 var events=fast.round_("Attack")
 check(events[0].actor=="Hero","Higher agility acts first")
 attributes.agility=1
 var slow=Combat.new(State.hero,attributes)
 slow.enemy_hp=99999
 events=slow.round_("Attack")
 check(events[0].actor=="Goblin","Lower agility acts after enemy")
 attributes.agility=10
 var tied=Combat.new(State.hero,attributes)
 events=tied.round_("Attack")
 check(events[0].actor=="Hero","Equal agility uses a deterministic hero-before-enemy tie")
 var dodges=0
 var no_dodges=0
 attributes.agility=100
 attributes.dexterity=80
 var evasive=Combat.new(State.hero,attributes)
 attributes.dexterity=0
 var plain=Combat.new(State.hero,attributes)
 for index in range(2000):
  for sim in [evasive,plain]:
   sim.h.hp=99999
   sim.enemy_hp=99999
   sim.round_("Defend")
  if evasive.events.any(func(event): return event.text=="Dodged"): dodges+=1
  if plain.events.any(func(event): return event.text=="Dodged"): no_dodges+=1
 check(dodges>520 and dodges<760 and no_dodges==0,"Dexterity produces bounded dodge odds; zero dexterity never dodges")
 check(is_equal_approx(GameRules.dodge_chance(9999),0.35) and is_equal_approx(GameRules.gold_chance(9999),0.60),"Dodge and gold probabilities have documented caps")
 # Agility/dexterity buffs are functional and expire instead of permanently changing stats.
 prepare("Rogue",["Ranger","Wizard"])
 State.hero.companion.active=false
 var buff_stats=State.stats()
 buff_stats.agility=3
 var buff_sim=Combat.new(State.hero,buff_stats)
 var first_round=buff_sim.round_("windstep")
 check(first_round[0].actor=="Goblin" and buff_sim.current_stat("agility")==11,"Windstep raises agility after a slow opening turn")
 var second_round=buff_sim.round_("feint")
 check(second_round[0].actor=="Hero" and buff_sim.current_stat("dexterity")==buff_stats.dexterity+10,"Agility buff changes next turn order; Feint raises dexterity")
 # A configured enemy also uses dexterity against physical attacks, without making spells miss.
 prepare("Rogue",["Wizard","Druid"])
 var dodging_enemy=Combat.new(State.hero,State.stats())
 dodging_enemy.enemy.dexterity=999
 var physical_dodges=0
 var spell_dodges=0
 for index in range(500):
  dodging_enemy.events=[]
  dodging_enemy.enemy_hp=99999
  dodging_enemy.hit_enemy("Hero",20,"Attack")
  if dodging_enemy.events[0].text=="Dodged": physical_dodges+=1
  dodging_enemy.events=[]
  dodging_enemy.hit_enemy("Hero",20,"Arcane Bolt")
  if dodging_enemy.events[0].text=="Dodged": spell_dodges+=1
 check(physical_dodges>130 and physical_dodges<220 and spell_dodges==0,"Enemy dexterity evades physical hits while guaranteed magic remains reliable")
 # Same seed and strategy must reproduce all dodge and spell rolls.
 prepare("Rogue",["Wizard","Druid"])
 var one=Combat.new(State.hero,State.stats())
 var two=Combat.new(State.hero,State.stats())
 one.auto_resolve()
 while two.outcome=="" and two.turns<200: two.round_(two.auto_action())
 check(one.h==two.h and one.enemy_hp==two.enemy_hp,"Normal and Auto share deterministic stat/status/dodge resolution")
 var bonus_count=0
 var seed_=137
 for index in range(2000):
  var reward=GameRules.gold_roll(100,80,seed_)
  if reward.bonus>0: bonus_count+=1
  seed_=reward.seed
 check(bonus_count>850 and bonus_count<1080,"Dexterity bonus-gold frequency matches its configured odds")
 check(GameRules.gold_roll(100,80,137)==GameRules.gold_roll(100,80,137),"Gold rewards are seeded and reproducible")
 prepare("Rogue")
 State.hero.seed=7
 var before=int(State.hero.gold)
 var reward=State.award_gold(100,"Test quest")
 check(reward.bonus==25 and State.hero.gold==before+125,"Quest rewards apply the dexterity bonus through the shared reward function")
 State.hero.seed=7
 before=int(State.hero.gold)
 State.reward(true)
 check(State.last_reward.bonus>0 and State.hero.gold==before+State.last_reward.total,"Battle rewards use the same bonus-gold rules")
 prepare("Paladin")
 State.hero.xp=69
 var points=int(State.hero.points)
 var before_stats=State.stats()
 State.reward(true)
 check(State.hero.level==2 and State.hero.points==points+2 and State.stats().max_hp>before_stats.max_hp,"Level-up grants two shared points and natural class stat growth")
 # Real 0.6 save migration retains progress and archives the fast demo skill purchases.
 prepare("Ranger")
 State.hero.level=4
 State.hero.xp=20
 State.hero.gold=73
 State.hero.journey.started=true
 State.hero.skills.Ranger=["oath","shield","light","mythic"]
 State.hero.weapon_skills.sword=["edge","flow"]
 var old=State.hero.duplicate(true)
 old.erase("progression_version")
 old.save_schema_version=2
 raw_save(old)
 State.reset()
 State.load_game()
 check(State.hero.level==4 and State.hero.xp==20 and State.hero.gold==73 and State.hero.journey.started,"Save migration retains hero level, XP, gold and quest progress")
 check(State.hero.points==8 and State.hero.skills.Ranger.is_empty() and State.hero.progression_archive.skills.Ranger.has("mythic"),"Fast demo investments are archived and respec to the correct new point budget")
 check(FileAccess.file_exists(State.SAVE+".v2.backup"),"Schema-two original is backed up before migration")
 State.save_game()
 State.hero.points-=1
 State.load_game()
 check(State.hero.points==8 and State.hero.progression_archive.skills.Ranger.has("mythic"),"Progression migration is idempotent on reload")
 print("Progression checks: %s Failures: %s" % [checks,failures])
 get_tree().quit(1 if failures else 0)

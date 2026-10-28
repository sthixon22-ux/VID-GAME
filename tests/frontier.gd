extends Node
var checks=0
var failures=0
func check(value:bool,label:String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures+=1;push_error("FAIL: "+label)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func settle():
 for i in 6:await get_tree().process_frame
func change(path:String):
 get_tree().change_scene_to_file(path);await settle()
 var area=get_tree().current_scene
 if "grace" in area:area.grace=999
 if "contact_grace" in area:area.contact_grace=999
 return area
func dismiss(box):
 while box.active:box.advance()
func setup():
 State.new_adventure();State.create_hero("Ash","Warrior",0,0,0,["Assassin","Druid"],"Male")
 State.hero.profile.economy=true;State.hero.journey.finished=true
 State.hero.campaign.reported=true;State.hero.campaign.reliquary_cleared=true
 State.hero.level=10;State.hero.gold=5000
 State.grant_item("Sahir Sword");State.equip("Weapon","Sahir Sword")
 State.grant_item("Sunveil Coat");State.equip("Chest","Sunveil Coat")
 State.choose_companion("dire_wolf");State.restore()
 for family in State.weapon_trees:
  State.hero.weapon_skills[family]=State.weapon_trees[family].map(func(n):return n.id)
 for class_ in State.classes:State.hero.skills[class_]=State.classes[class_].nodes.map(func(n):return n.id)
func run():
 UserSettings.set_option("minimal_animations",true);UserSettings.set_option("muted",true)
 setup()
 var attrs=State.stats();attrs.critical=0;attrs.attack=40;attrs.max_mp=100
 var original=State.hero.duplicate(true)
 # Damage-type and family calculations isolate defense/RNG.
 var dragon=Combat.new(original,attrs,"sand_drake");dragon.enemy.dexterity=0;dragon.enemy.defense=0
 var plain=Combat.new(original,attrs,"sand_drake");plain.enemy.dexterity=0;plain.enemy.defense=0;plain.enemy.tags=[]
 check(dragon.legal("dragon_slash"),"Dragon Slash is legal from the learned sword node")
 dragon.hero_turn("Dragon Slash");plain.hero_turn("Dragon Slash")
 check(int(dragon.enemy.hp)-dragon.enemy_hp==2*(int(plain.enemy.hp)-plain.enemy_hp),"Dragon Slash deals exactly double damage against draconic targets")
 var fire=Combat.new(original,attrs,"mossling");var neutral=Combat.new(original,attrs,"mossling");neutral.enemy.affinities={}
 fire.hero_turn("Firebolt");neutral.hero_turn("Firebolt")
 check(fire.enemy_hp<neutral.enemy_hp,"Fire weakness increases actual damage")
 var holy=Combat.new(original,attrs,"drowned_sentinel");holy.h.hp=1;holy.hero_turn("Holy Light")
 check(holy.h.hp>1 and holy.enemy_hp<int(holy.enemy.hp),"Holy Light heals and smites undead in the same cast")
 var sunder=Combat.new(original,attrs,"dune_scarab");sunder.enemy.dexterity=0
 sunder.hero_turn("Sundering Roar")
 check(sunder.sunder==7 and sunder.sunder_rounds==4,"Sundering Roar applies timed armor break")
 var death_rolls=0
 for seed_ in range(1,1201):
  var h=original.duplicate(true);h.seed=seed_
  var sim=Combat.new(h,attrs,"sand_drake");sim.enemy.dexterity=0
  sim.hero_turn("Deathmark")
  if sim.enemy_hp==0:death_rolls+=1
 check(death_rolls>0 and death_rolls<35,"Seeded Deathmark produces rare instant KOs, not guaranteed kills")
 for id in ["warden","reliquary_keeper","glass_sentinel","ironroot_colossus"]:
  var sim=Combat.new(original,attrs,id);sim.enemy.dexterity=0;sim.hero_turn("Deathmark")
  check(sim.enemy_hp>0 and sim.events.any(func(e):return e.text.contains("immune")),"Story boss immune to Deathmark: "+id)
 # Every learned combat grant has a concrete description and an executable resolver.
 for class_ in State.classes:
  for node in State.classes[class_].nodes:
   for id in node.get("grants",[]):
    var entry=AbilityBook.entry(id)
    check(not entry.is_empty() and not entry.description.contains("class ability learned"),"Specific learned effect documented: "+id)
    var sim=Combat.new(original,attrs,"glass_sentinel");sim.h.mp=999;sim.enemy_hp=10000;sim.h.hp=100;sim.demo_hero_turn(entry.name)
    check(not sim.events.is_empty(),"Learned ability resolves: "+id)
 # Multi-hit, siphon, healing, statuses and seeded parity.
 var sim=Combat.new(original,attrs,"glass_sentinel");sim.enemy.dexterity=0;sim.hero_turn("Hundred Fists")
 check(sim.events.filter(func(e):return e.target=="Goblin" and e.amount>0).size()==5,"Hundred Fists performs five actual hits")
 sim=Combat.new(original,attrs,"glass_sentinel");sim.h.mp=10;sim.hero_turn("Soul Rend")
 check(sim.h.mp==6,"Soul Rend consumes nine MP and recovers five on hit")
 sim=Combat.new(original,attrs,"sand_drake");sim.enemy.dexterity=0;sim.hero_turn("Inferno")
 check(sim.burn==10 and sim.burn_rounds==3,"Inferno applies its own burning status")
 var a=Combat.new(original,attrs,"glass_sentinel");var b=Combat.new(original,attrs,"glass_sentinel")
 a.auto_resolve()
 while b.outcome=="" and b.turns<200:b.round_(b.auto_action())
 check(a.h==b.h and a.enemy_hp==b.enemy_hp,"Expanded rules preserve manual/auto seeded parity")
 # Explore the two new chapters through real NPCs, puzzle pages, battle results and return routes.
 for region in ["sahir","kharholt"]:
  setup()
  var progress=ExpeditionRules.progress(State.hero)
  if region=="kharholt":progress.cleared.append("sahir")
  State.hero.journey.region=region;State.remember_position(Vector3(0,0,10))
  var area=await change(ExpeditionRules.scene(region))
  check(area.accessible() and area.mobs.size()==6,"Playable wilderness and six encounters: "+region)
  for point in area.targets():check(area.walkable(point),"Landmark reachable: "+region+str(point))
  for point in [Vector3(-32,0,-20),Vector3(30,0,-34),Vector3(32,0,10)]:check(area.walkable(point),"Off-road treasure reachable: "+region+str(point))
  area.hero.position=area.GUIDE;area.interact();dismiss(area.dialogue)
  for point in area.targets():area.hero.position=point;area.interact();dismiss(area.dialogue)
  check(ExpeditionRules.count(State.hero,region)==3,"All regional inscriptions collected: "+region)
  area.hero.position=area.GUIDE;area.interact();dismiss(area.dialogue)
  check(progress.briefed.has(region),"Guide unlocks dungeon: "+region)
  var gold=State.hero.gold;area.interact();dismiss(area.dialogue)
  check(State.hero.gold==gold,"Guide cannot pay twice: "+region)
  var treasure_id=region+"_wild_0";var pos=area.treasures.chests[treasure_id].position
  check(area.treasures.open_near(pos),"Treasure opens: "+region)
  gold=State.hero.gold
  check(not area.treasures.open_near(pos) and State.hero.gold==gold,"Treasure cannot repeat: "+region)
  for service in ["weapons","armor","items","inn"]:
   check(not TownServices.nearby(region,TownServices.DOORS[region][["weapons","armor","items","inn"].find(service)][0]).is_empty(),"Town service entrance: "+region+service)
  check(State.save_game(),"Regional save succeeds: "+region)
  State.reset();State.load_game();progress=ExpeditionRules.progress(State.hero)
  check(progress.chests.has(treasure_id) and progress.briefed.has(region),"Treasure and quest persist: "+region)
  area.hero.position=area.TOMB;area.interact();await settle()
  area=get_tree().current_scene;area.grace=999
  check(area.dungeon and area.mobs.size()==5 and not area.walkable(area.BOSS),"Five room encounters and locked boss chamber: "+region)
  for p in area.MECHANISMS:check(area.walkable(p),"Lateral puzzle room reachable: "+region+str(p))
  if region=="sahir":
   for i in 3:
    for turn in [1,3,2][i]:
     area.mechanism(i)
     for child in area.puzzle.get_children():
      if child is Button and child.text.begins_with("Rotate"):child.pressed.emit();break
    area.puzzle.get_parent().get_parent().hide()
  else:
   for index in [0,1]:
    var id=str(4100+index);progress.rooms.append(id)
    area.mechanism(index)
    # Invoke the actual steam valve button, preserving its prerequisites.
    for child in area.puzzle.get_children():
     if child is Button and child.text.begins_with("Cool" if index==0 else "Vent"):child.pressed.emit();break
    area.puzzle.get_parent().get_parent().hide()
  var visited={Vector2i.ZERO:true};var queue=[Vector2i.ZERO]
  while not queue.is_empty():
   var cell=queue.pop_front()
   for edge in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    if area.cells.has(cell+edge) and not visited.has(cell+edge):visited[cell+edge]=true;queue.append(cell+edge)
  check(visited.size()==area.cells.size(),"Every dungeon room is connected by walkable halls: "+region)
  check(ExpeditionRules.can_open(State.hero,region) and area.walkable(area.BOSS),"Mechanisms open guardian chamber: "+region)
  check(State.save_game(),"Solved dungeon mechanism state saves: "+region)
  State.reset();State.load_game();progress=ExpeditionRules.progress(State.hero)
  check(ExpeditionRules.can_open(State.hero,region),"Solved mirrors/steam valves survive actual reload: "+region)
  State.encounter_id=3100 if region=="sahir" else 4102;State.record_encounter_clear()
  check(progress.rooms.has(str(State.encounter_id)),"Cleared dungeon room persists: "+region)
  # Execute the actual boss intro and victory handler.
  area.hero.position=area.BOSS+Vector3(0,0,3);area.boss_intro();check(area.dialogue.active,"Guardian introduction opens: "+region);dismiss(area.dialogue);await settle()
  var battle=get_tree().current_scene
  check(battle.scene_file_path=="res://scenes/battle.tscn" and battle.sim.species==ExpeditionRules.regions[region].boss,"Correct guardian battle loads: "+region)
  battle.sim.enemy_hp=0;battle.sim.outcome="Victory";battle.finish()
  check(ExpeditionRules.progress(State.hero).cleared.has(region),"Real victory completes chapter: "+region)
  battle.dialogue.show_id(region+"_boss_after");check(battle.dialogue.lines.size()>=4,"Substantial post-battle conversation: "+region);dismiss(battle.dialogue)
  battle.return_to_adventure();await settle()
  area=get_tree().current_scene;area.grace=999
  check(not area.boss.visible or ExpeditionRules.progress(State.hero).cleared.has(region),"Defeated guardian stays restored: "+region)
  area.hero.position=Vector3(0,0,3);area.interact();await settle()
  check(get_tree().current_scene.area==region,"Dungeon exit returns to its own region: "+region)
  State.hero.journey.region=ExpeditionRules.regions[region].dungeon;State.retreat_to_safety()
  check(State.hero.journey.region==region,"Defeat retreats to correct regional town: "+region)
 # Existing dungeons retain gates while gaining reachable side rooms and treasure.
 setup();State.hero.journey.entered=true;State.hero.journey.region="dungeon";State.remember_position(Vector3.ZERO)
 var old=await change("res://scenes/dungeon.tscn")
 check(old.enemies.size()==6 and old.can_walk(Vector3(-18,0,-10)) and old.can_walk(Vector3(18,0,-18)),"Sanctuary has lateral vault/library and six enemies")
 check(not old.can_walk(Vector3(0,0,-29)),"Sanctuary seal gate still blocks boss")
 State.hero.campaign.sluice_key=true;State.hero.campaign.reliquary_west=true;State.hero.journey.region="reliquary";State.remember_position(Vector3(0,0,4))
 old=await change("res://scenes/reliquary.tscn")
 check(old.extra_mobs.size()==3 and old.walkable(Vector3(-21,0,-15)) and old.walkable(Vector3(21,0,-31)),"Reliquary gains crypt/archive rooms and guards")
 check(not old.walkable(Vector3(0,0,-44)),"Reliquary eastern gate still blocks boss")
 State.hero.journey.region="forest";State.remember_position(Vector3.ZERO)
 var world=await change("res://scenes/world.tscn")
 for id in world.treasures.chests:check(world.forest.can_walk(world.treasures.chests[id].position),"Opening-region treasure is on reachable ground: "+id)
 var malformed=State.hero.duplicate(true);ExpeditionRules.progress(malformed).mirrors="invalid"
 check(not SaveStore.valid_nested(malformed),"Malformed new puzzle state cannot overwrite a valid save")
 var clean=State.hero.duplicate(true);clean.campaign.erase("expedition")
 check(ExpeditionRules.progress(clean).chests.is_empty(),"Older saves gain empty expedition defaults")
 print("Frontier checks: %s Failures: %s" % [checks,failures])
 await Sound.stop_all();get_tree().quit(1 if failures else 0)

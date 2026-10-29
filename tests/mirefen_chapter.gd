extends Node
var checks:=0
var failures:=0
func check(value:bool,label:String):
 checks+=1
 if not value:failures+=1;push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _ready():
 get_tree().current_scene=null
 call_deferred("run")
func settle():
 for i in 6:await get_tree().process_frame
func scene(path:String):
 get_tree().change_scene_to_file(path)
 await settle()
 var area=get_tree().current_scene
 if "grace" in area:area.grace=999
 return area
func dismiss(box:Dialogue):
 while box.active:box.advance()
func interact_at(area,pos:Vector3):
 area.hero.position=pos
 area.interact()
 if "dialogue" in area:dismiss(area.dialogue)
func run():
 UserSettings.set_option("minimal_animations",true)
 State.new_adventure()
 State.create_hero("Marsh Tester","Wizard",0,0,0,["Monk","Assassin"],"Male")
 State.buy("Oak Staff")
 State.equip("Weapon","Oak Staff")
 State.hero.journey.finished=true
 State.hero.journey.boss=true
 State.hero.demo.first_choice=true
 State.choose_companion("spirit_fox")
 State.hero.journey.region="mirefen"
 State.remember_position(Vector3(0,0,4))
 var saved_classes=[State.hero.primary,State.hero.secondary.duplicate(),State.hero.profile.sex]
 var area=await scene("res://scenes/mirefen.tscn")
 check(area.hero is HeroVisual and area.companion is CompanionActor,"Approved hero and companion art survives region travel")
 check(area.walkable(Vector3(0,0,-40)) and area.walkable(Vector3(12,0,-40)) and not area.walkable(Vector3(19,0,-40)),"Marsh causeway and new side boardwalk are walkable; deep banks bounded")
 check(not area.walkable(Vector3(-8,0,-5)),"Settlement cottages block movement")
 interact_at(area,area.RELIQUARY_GATE)
 check(get_tree().current_scene==area and not State.hero.campaign.sluice_key,"Dungeon access requires investigation, not class or gear")
 interact_at(area,area.ROYAL)
 check(State.hero.campaign.audience,"King Aldren audience completes via actual dialogue")
 var gold=int(State.hero.gold)
 interact_at(area,area.ROYAL)
 check(State.hero.gold==gold,"Royal purse cannot be farmed")
 interact_at(area,area.IONA)
 check(State.hero.campaign.investigating,"Local investigation starts")
 for pos in area.SURVEYS:interact_at(area,pos)
 check(State.hero.campaign.readings.size()==3,"All three water surveys recorded")
 interact_at(area,area.IONA)
 check(State.hero.campaign.sluice_key,"Iona awards access through completed dialogue")
 interact_at(area,area.SELLA)
 for pos in area.REEDS:interact_at(area,pos)
 check(State.hero.side_quests.silverreed==4,"Four distinct silverreed bundles gathered")
 gold=State.hero.gold
 interact_at(area,area.SELLA)
 check(State.hero.side_quests.claimed.has("silverreed") and State.hero.gold>gold,"Sella pays once for medicine errand")
 gold=State.hero.gold
 interact_at(area,area.SELLA)
 check(State.hero.gold==gold,"Medicine reward cannot repeat")
 interact_at(area,area.JORY)
 for i in 3:State.reward(true,"reed_stalker")
 interact_at(area,area.JORY)
 check(State.hero.side_quests.claimed.has("causeway"),"Jory’s patrol uses real regional victory counters")
 # Shops use normal purchase, equipment and preview paths.
 State.shop_id="reedcross_weapons"
 State.hero.gold=1000
 check(State.buy("Runekeeper Staff") and State.equip("Weapon","Runekeeper Staff"),"Regional weapon purchasable and equippable")
 check(not State.buy("Wildheart Mantle"),"Weapon stall rejects armor stock")
 State.shop_id="reedcross_armor"
 check(State.buy("Wildheart Mantle") and State.equip("Chest","Wildheart Mantle"),"Armorer uses same owned equipment rules")
 check(State.save_game(),"Campaign and equipment save")
 State.reset();State.load_game()
 check([State.hero.primary,State.hero.secondary,State.hero.profile.sex]==saved_classes,"Three classes and appearance retained after region save/load")
 check(State.hero.campaign.sluice_key and State.hero.side_quests.claimed.has("silverreed"),"Investigation and sidequest rewards persist")
 State.hero.journey.region="reliquary"
 State.remember_position(Vector3(0,0,4))
 area=await scene("res://scenes/reliquary.tscn")
 check(area.water_surfaces[0].position.y>0,"Floodwater surface is visibly above the corridor floor")
 check(not area.walkable(Vector3(0,0,-23)),"Flooded western basin blocks progression")
 interact_at(area,area.EAST)
 check(not State.hero.campaign.reliquary_east,"East diversion cannot bypass west drain")
 interact_at(area,area.WEST)
 check(State.hero.campaign.reliquary_west and area.walkable(Vector3(0,0,-23)),"West drain opens basin floor")
 State.save_game();State.reset();State.load_game()
 check(State.hero.campaign.reliquary_west and not State.hero.campaign.reliquary_east,"Partial floodgate save resumes")
 area=await scene("res://scenes/reliquary.tscn")
 check(area.water_surfaces[0].position.y< -1,"Water level restored visually on load")
 interact_at(area,area.CACHE)
 gold=State.hero.gold
 interact_at(area,area.CACHE)
 check(State.hero.campaign.cache and State.hero.gold==gold,"Hidden cache is persistent and cannot repeat")
 interact_at(area,area.EAST)
 check(area._open() and area.walkable(Vector3(0,0,-44)),"Diversion opens heart chamber")
 # Unique simulator actions, seeded reproducibility, and actual presentation.
 State.hero.hp=500;State.hero.mp=100
 var attrs=State.stats();attrs.max_hp=500;attrs.max_mp=100
 var a=Combat.new(State.hero,attrs,"reliquary_keeper")
 var b=Combat.new(State.hero,attrs,"reliquary_keeper")
 check(JSON.stringify(a.round_("Defend"))==JSON.stringify(b.round_("Defend")),"Keeper simulation remains deterministic")
 check(a.charging,"Keeper telegraphs tide on first round")
 var hp=int(a.h.hp)
 var events=a.round_("Defend")
 check(events.any(func(e):return e.text=="Oathbreaker Tide") and a.h.hp<hp,"Telegraphed tide executes through standard simulator")
 State.hero.level=8;State.restore()
 for id in ["mire_leech","bog_wisp","reed_stalker","drowned_sentinel"]:
  var sim=Combat.new(State.hero,State.stats(),id)
  var hp_fixed=int(sim.enemy.hp)
  var high=State.hero.duplicate(true);high.level=40
  check(Combat.new(high,State.stats(),id).enemy.hp==hp_fixed,"Fixed regional stats: "+id)
  sim.auto_resolve()
  check(sim.outcome in ["Victory","Defeat"],"Regional auto simulation terminates: "+id)
 State.hero.monsters.mire_leech=9
 State.reward(false,"mire_leech")
 check(State.species_wins("mire_leech")==9,"Auto victory does not grant mastery")
 State.reward(true,"mire_leech")
 check(State.species_wins("mire_leech")==10,"Ten normal victories unlock regional mastery")
 State.hero.journey.region="reliquary"
 State.hero.campaign.reliquary_west=true;State.hero.campaign.reliquary_east=true
 State.enemy_id="reliquary_keeper";State.encounter_id=2300
 State.hero.level=15;State.restore()
 area=await scene("res://scenes/battle.tscn")
 area.sim.enemy_hp=1
 area.sim.enemy.dexterity=0
 area.sim.stats.agility=999
 await area.act("Attack")
 await settle()
 check(State.hero.campaign.reliquary_cleared,"Actual cinematic battle victory completes dungeon")
 State.hero.journey.region="mirefen"
 State.remember_position(Vector3(0,0,4))
 area=await scene("res://scenes/mirefen.tscn")
 interact_at(area,area.IONA)
 check(State.hero.campaign.reported and State.hero.campaign.desert_clue,"Return dialogue pays chapter reward and records desert clue")
 gold=State.hero.gold
 interact_at(area,area.IONA)
 check(State.hero.gold==gold,"Main chapter reward is one-time")
 State.save_game();State.reset();State.load_game()
 check(State.hero.campaign.reliquary_cleared and State.hero.campaign.reported,"Completed chapter persists")
 State.hero.journey.region="reliquary";State.retreat_to_safety()
 check(State.hero.journey.region=="mirefen" and State.return_position==Vector3(0,0,-10),"Regional defeat returns to Reedcross inn")
 area=await scene("res://scenes/mirefen.tscn")
 interact_at(area,area.RETURN_GATE)
 await settle()
 check(get_tree().current_scene.scene_file_path=="res://scenes/world.tscn","Return to original Willowbrook remains available")
 var original=get_tree().current_scene
 original.hero.position=Vector3(0,0,13)
 original.interact()
 await settle()
 check(get_tree().current_scene.scene_file_path=="res://scenes/mirefen.tscn","Completed opening can re-enter marsh through actual road interaction")
 # Same-seed guard comparison isolates the boss's mechanical counter.
 var h=State.hero.duplicate(true)
 h.companion.active=false
 h.hp=1000
 var stats=State.stats();stats.defense=10;stats.dexterity=0;stats.max_hp=1000
 var guarded=Combat.new(h,stats,"reliquary_keeper")
 var exposed=Combat.new(h,stats,"reliquary_keeper")
 guarded.charging=true;guarded.guarding=true
 exposed.charging=true
 guarded.enemy_turn();exposed.enemy_turn()
 check(guarded.h.hp>exposed.h.hp,"Defend materially reduces the Keeper’s telegraphed tide")
 var malformed=State.hero.duplicate(true)
 malformed.campaign.readings="invalid"
 check(not SaveStore.valid_nested(malformed),"Malformed campaign collection save is rejected")
 malformed=State.hero.duplicate(true);malformed.campaign.reliquary_west="invalid"
 check(not SaveStore.valid_nested(malformed),"Malformed campaign completion flag is rejected")
 var legacy=State.hero.duplicate(true)
 legacy.erase("campaign")
 check(SaveStore.write_hero(legacy,State.SAVE),"Legacy save without campaign data remains writable")
 State.hero.campaign.reliquary_cleared=true
 State.load_game()
 check(not State.hero.campaign.reliquary_cleared and State.hero.campaign.readings.is_empty(),"Legacy load receives defaults instead of inheriting current-session chapter progress")
 # Region-appropriate tuning smoke: uninvested level-six three-class builds can finish.
 var names=State.classes.keys()
 for i in names.size():
  State.reset()
  State.hero.primary=names[i]
  State.hero.secondary=[names[(i+1)%names.size()],names[(i+2)%names.size()]]
  State.hero.level=6
  State.hero.profile.economy=true
  State.hero.profile.created=true
  State.hero.journey.finished=true
  State.hero.equipment={"Weapon":"None","Shield":"None","Helmet":"None","Chest":"None","Gauntlets":"None","Pants":"None","Boots":"None","Accessory":"None"}
  State.shop_id="reedcross_weapons"
  State.hero.gold=1000
  var weapon=""
  for item in ShopBook.stock(State.shop_id):
   if State.compatible(item):weapon=item;break
  check(not weapon.is_empty(),"Regional weapon coverage: "+names[i])
  State.buy(weapon);State.equip("Weapon",weapon)
  State.shop_id="reedcross_armor"
  State.buy("Wildheart Mantle");State.equip("Chest","Wildheart Mantle")
  State.choose_companion("dire_wolf")
  State.restore()
  var trial=Combat.new(State.hero,State.stats(),"reliquary_keeper")
  trial.auto_resolve()
  check(trial.outcome=="Victory","Level-six regional gear/companion boss viability: "+names[i])
 print("Mirefen chapter checks: %s Failures: %s" % [checks,failures])
 get_tree().quit(1 if failures else 0)

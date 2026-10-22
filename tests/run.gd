extends Node
var failures=0
var total=0
func check(value: bool, title: String):
 total+=1
 if value: print("PASS: ",title)
 else:
  failures+=1
  push_error(title)
func _ready():
 # Keep the runner alive while exercising actual scene transitions.
 get_tree().current_scene=null
 call_deferred("run")
func settle():
 await get_tree().process_frame
 await get_tree().process_frame
func dismiss(box: Dialogue):
 var safety=0
 while box.active and safety<30:
  box.advance()
  safety+=1
func scene(path: String):
 get_tree().change_scene_to_file(path)
 await settle()
 return get_tree().current_scene
func run():
 Engine.time_scale=8.0
 State.reset()
 State.cleared_until.clear()
 State.enemy_id="goblin"
 State.return_position=Vector3.ZERO
 var original=State.hero.duplicate(true)
 var s=State.stats()
 var a=Combat.new(original,s)
 var b=Combat.new(original,s)
 a.auto_resolve()
 while b.outcome=="":
  var action="Attack"
  if b.h.hp<s.max_hp/2 and b.h.mp>=8: action="Regrowth"
  elif b.h.mp>=7: action="Sacred Strike"
  b.round_(action)
 check(a.h==b.h and a.enemy_hp==b.enemy_hp,"Auto/normal seeded parity")
 check(a.outcome=="Victory" and a.h.mp<original.mp,"Starter victory consumes MP")
 var weak=original.duplicate(true)
 weak.hp=1
 weak.mp=0
 weak.companion.active=false
 var lose=Combat.new(weak,{"attack":1,"defense":0,"speed":1,"max_hp":110,"max_mp":35})
 check(lose.auto_resolve()=="Defeat","Auto can lose")
 var mythic=original.duplicate(true)
 mythic.investments.Ranger=4
 mythic.skills.Ranger=["oath","shield","light","mythic"]
 check(not Combat.new(mythic,s).legal("Wild Hunt"),"Secondary mythic remains unavailable")
 mythic.primary="Ranger"
 check(Combat.new(mythic,s).legal("Wild Hunt"),"Primary mythic activates")
 State.hero.equipment.Weapon="Sunsteel Sword"
 check(State.stats().attack>s.attack,"Equipment changes stats")
 State.hero=original.duplicate(true)
 State.reward(false)
 check(State.hero.mastery==0,"Auto does not advance normal mastery")
 State.reward(true,"mossling")
 check(State.hero.mastery==0,"Other species do not advance goblin mastery")
 for i in range(10): State.reward(true)
 check(State.hero.mastery==10 and State.hero.level>1,"Normal wins grant mastery and levels")
 # Match the intentional floating-point position normalization used on load.
 State.hero.town_visit.position=[0.0,0.0,0.0]
 State.save_game()
 var saved=State.hero.duplicate(true)
 State.reset()
 State.load_game()
 check(State.hero==saved,"Save round trip")
 # Old version saves omit the new journey section and nested fields.
 var legacy=original.duplicate(true)
 legacy.erase("journey")
 var file=FileAccess.open(State.SAVE,FileAccess.WRITE)
 file.store_string(JSON.stringify(legacy))
 file.close()
 State.reset()
 State.load_game()
 check(State.hero.journey.seals.is_empty() and not State.hero.journey.boss,"Legacy saves receive story defaults")
 State.remember_position(Vector3(1.25,0,-3.75))
 State.save_game()
 State.reset()
 State.load_game()
 check(State.return_position.is_equal_approx(Vector3(1.25,0,-3.75)),"Fractional exploration position survives saving")
 var empty=Combat.new(original,s)
 empty.h.mp=0
 check(empty.round_("Sacred Strike").is_empty() and empty.turns==0,"Unaffordable spells do not spend a turn")
 check(empty.round_("Unknown ability").is_empty(),"Unknown combat commands are rejected")
 State.hero=original.duplicate(true)
 State.return_position=Vector3.ZERO
 var world=await scene("res://scenes/world.tscn")
 check(world.goblins.size()==6,"Forest and plains contain six roaming encounters")
 check(not world.forest.can_walk(Vector3(18,0,-40)) and world.forest.can_walk(Vector3(18,0,-54)),"Bridge is the river crossing")
 check(not world.forest.can_walk(Vector3(-8,0,5)),"Houses block movement")
 var reachable=walkable_cells(world.forest)
 for destination in world.forest.herb_positions+Forest.CRYSTALS+Forest.QUEST_NPCS+[Forest.SHRINE]:
  var found=false
  for cell in reachable:
   if Vector2(cell.x-destination.x,cell.y-destination.z).length()<1.5:
    found=true
    break
  check(found,"Quest destination reachable from village: %s" % destination)
 world.hero.position=Forest.SHRINE
 world.interact()
 check(world.dialogue.active and State.hero.exploration.shrine,"Shrine discovery opens locked-door dialogue")
 dismiss(world.dialogue)
 check(get_tree().current_scene==world,"Sanctuary cannot be entered before quest completion")
 world.hero.position=Vector3(-2.6,0,-0.8)
 world.interact()
 check(world.dialogue.active and State.hero.journey.started,"Mira starts the story with portrait dialogue")
 var frozen=world.hero.position
 world._process(0.016)
 check(world.hero.position==frozen,"Dialogue preserves exploration position")
 dismiss(world.dialogue)
 for herb in world.forest.herbs:
  world.hero.position=herb.position
  world.interact()
 check(State.hero.exploration.herbs.size()==3,"Three distinct herbs gathered")
 var potions=State.hero.potions
 world.interact()
 check(State.hero.potions==potions,"Herbs cannot reward twice")
 world.hero.position=Vector3(-2.6,0,-0.8)
 var gold=State.hero.gold
 world.interact()
 check(State.hero.exploration.quest_done and State.last_reward.base==60 and State.hero.gold==gold+State.last_reward.total,"Mira awards quest supplies including any dexterity bonus")
 var quest_gold=State.hero.gold
 dismiss(world.dialogue)
 world.interact()
 dismiss(world.dialogue)
 check(State.hero.gold==quest_gold,"Quest reward cannot repeat")
 world.hero.position=world.goblins[0].position
 world.encounter(true)
 check(world.message.contains("10 normal"),"Auto locked before mastery")
 State.hero.mastery=10
 world.encounter(true)
 check(world.auto_panel.active,"Auto opens a risk preview without changing scene")
 world.auto_panel.resolve()
 check(State.cleared_until.has(0) and get_tree().current_scene==world,"Auto resolves without scene transition and clears encounter")
 world.auto_panel.close()
 State.restore()
 world.hero.position=Forest.SHRINE
 world.interact()
 dismiss_keyboard(world.dialogue,KEY_E)
 await settle()
 var dungeon=get_tree().current_scene
 check(dungeon.scene_file_path=="res://scenes/dungeon.tscn" and State.hero.journey.region=="dungeon","Shrine dialogue enters the dungeon")
 dismiss(dungeon.dialogue)
 check(dungeon.can_walk(Vector3(0,0,-20)) and not dungeon.can_walk(Vector3(20,0,-20)),"Dungeon floors constrain movement")
 dungeon.hero.position=Vector3(0,0,-27)
 dungeon.interact()
 check(dungeon.dialogue.active,"Boss is gated by two seals")
 dismiss(dungeon.dialogue)
 # Execute each real guardian battle and return to its seal.
 for i in range(2):
  dungeon.hero.position=dungeon.seals[i].position
  dungeon.interact()
  await settle()
  var battle=get_tree().current_scene
  check(battle.sim.species=="mossling","Seal guardian uses mossling data")
  while battle.sim.outcome=="":
   battle.act("Sword Slash")
   while battle.busy: await get_tree().process_frame
  check(battle.sim.outcome=="Victory" and State.hero.journey.guards.has(i),"Guardian victory persists")
  battle.return_to_adventure()
  await settle()
  dungeon=get_tree().current_scene
  solve_puzzle(i)
  dungeon.hero.position=dungeon.seals[i].position
  dungeon.interact()
  check(State.hero.journey.seals.has(i),"Unguarded seal can be cleansed")
  dismiss(dungeon.dialogue)
 dungeon.hero.position=dungeon.chest.position
 dungeon.interact()
 dismiss(dungeon.dialogue)
 check(State.hero.journey.chest and State.hero.hp==State.stats().max_hp,"Dungeon cache restores party")
 potions=State.hero.potions
 dungeon.interact()
 check(State.hero.potions==potions,"Cache reward cannot repeat")
 # Verify telegraph mechanics directly without bypassing the boss integration.
 var boss_hero=State.hero.duplicate(true)
 boss_hero.hp=State.stats().max_hp
 var charge=Combat.new(boss_hero,State.stats(),"warden")
 charge.round_("Defend")
 charge.round_("Defend")
 check(charge.charging,"Boss telegraphs its heavy attack")
 var before=int(charge.h.hp)
 charge.round_("Defend")
 check(not charge.charging and before-charge.h.hp<35,"Defend mitigates the telegraphed attack")
 dungeon.hero.position=Vector3(0,0,-27)
 dungeon.interact()
 dismiss_keyboard(dungeon.dialogue,KEY_SPACE)
 await settle()
 var boss_battle=get_tree().current_scene
 check(boss_battle.sim.species=="warden","Boss intro launches the correct battle")
 var rounds=0
 while boss_battle.sim.outcome=="" and rounds<35:
  var action="Sword Slash"
  if boss_battle.sim.charging: action="Defend"
  elif boss_battle.sim.h.hp<55 and boss_battle.sim.h.potions>0: action="Items"
  elif boss_battle.sim.h.mp>=7: action="Sacred Strike"
  boss_battle.act(action)
  while boss_battle.busy: await get_tree().process_frame
  rounds+=1
 check(boss_battle.sim.outcome=="Victory" and State.hero.journey.boss,"Prepared party can win the boss fight")
 check(State.hero.equipment.Weapon=="Sunsteel Sword","Boss awards the living ember weapon")
 check(State.hero.mastery==10,"Dungeon fights do not add goblin mastery")
 boss_battle.dialogue.show_id("boss_win",boss_battle.return_to_adventure)
 dismiss_keyboard(boss_battle.dialogue,KEY_ENTER)
 await settle()
 dungeon=get_tree().current_scene
 check(not dungeon.boss.visible,"Freed boss stays absent after return")
 dungeon.hero.position=Vector3.ZERO
 dungeon.interact()
 await settle()
 world=get_tree().current_scene
 check(world.scene_file_path=="res://scenes/world.tscn","Dungeon exit returns to the shrine")
 world.hero.position=Vector3(-2.6,0,-0.8)
 world.interact()
 dismiss(world.dialogue)
 check(State.hero.journey.finished and world.completion.get_parent().get_parent().visible,"Ending dialogue completes the adventure")
 gold=State.hero.gold
 world.completion.get_parent().get_parent().hide()
 world.interact()
 dismiss(world.dialogue)
 check(State.hero.gold==gold,"Ending reward cannot repeat")
 State.save_game()
 State.reset()
 State.load_game()
 check(State.hero.journey.finished and State.hero.journey.seals.size()==2,"Complete story survives save/load")
 # Defeat recovery must not set story victory.
 State.hero=original.duplicate(true)
 State.enemy_id="warden"
 State.hero.journey.region="dungeon"
 var defeat=await scene("res://scenes/battle.tscn")
 defeat.sim.h.hp=0
 defeat.sim.outcome="Defeat"
 defeat.finish()
 check(not State.hero.journey.boss and State.hero.journey.region=="forest","Defeat retreats safely without completing boss")
 State.hero=original
 State.return_position=Vector3.ZERO
 State.enemy_id="goblin"
 State.save_game()
 await scene("res://scenes/title.tscn")
 print("Checks: ",total," Failures: ",failures)
 get_tree().quit(1 if failures else 0)

func walkable_cells(forest: Forest) -> Dictionary:
 var visited={Vector2i.ZERO:true}
 var queue=[Vector2i.ZERO]
 var index=0
 var blocked: Dictionary={}
 while index<queue.size():
  var cell: Vector2i=queue[index]
  index+=1
  for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var next=cell+direction
   if visited.has(next) or blocked.has(next): continue
   if forest.can_walk(Vector3(next.x,0,next.y)):
    visited[next]=true
    queue.append(next)
   else: blocked[next]=true
 return visited

func dismiss_keyboard(box: Dialogue, key: Key):
 var viewport=box.get_viewport()
 var consumed=[false]
 box.closed.connect(func(): consumed[0]=viewport.is_input_handled(),CONNECT_ONE_SHOT)
 var safety=0
 while box.active and safety<30:
  var press=InputEventKey.new()
  press.keycode=key
  press.pressed=true
  viewport.push_input(press)
  var release=InputEventKey.new()
  release.keycode=key
  release.pressed=false
  viewport.push_input(release)
  safety+=1
 check(not box.active,"Keyboard %s closes dialogue, including scene-changing callbacks" % OS.get_keycode_string(key))
 check(consumed[0],"Keyboard %s is consumed before the dialogue closes or changes scenes" % OS.get_keycode_string(key))

func solve_puzzle(index:int):
 if index==0:
  for dial in range(3):
   for turn in [1,3,2][dial]: State.puzzle_dial(dial)
 else:
  for note in [2,0,1]: State.puzzle_note(note)

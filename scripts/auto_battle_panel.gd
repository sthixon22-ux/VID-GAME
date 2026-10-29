class_name AutoBattlePanel
extends CanvasLayer
signal closed
signal fight_requested
var active=false
var content: VBoxContainer
var shade: ColorRect
var species="goblin"
var resolved=false
func _ready():
 layer=30
 shade=ColorRect.new()
 shade.color=Color(0.01,0.02,0.04,0.8)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 content=UI.panel(self,Vector2(330,150),Vector2(620,420))
 content.get_parent().get_parent().get_parent().layer=31
 close()
func clear():
 for child in content.get_children():
  content.remove_child(child)
  child.queue_free()
func open(species_: String="goblin", offer_normal:bool=false):
 species=species_
 resolved=false
 active=true
 shade.show()
 content.get_parent().get_parent().show()
 clear()
 UI.label(content,"AUTO-BATTLE / "+species.to_upper()).add_theme_font_size_override("font_size",25)
 var wins=State.species_wins(species)
 if species in ["warden","reliquary_keeper","glass_sentinel","ironroot_colossus"] or wins<10:
  UI.label(content,"Requires 10 normal victories for this species.\nStory guardians must be fought normally.")
 else:
  var forecast=Combat.new(State.hero,State.stats(),species)
  forecast.auto_resolve()
  var ratio=float(forecast.h.hp)/float(State.stats().max_hp)
  var risk="CERTAIN DEFEAT" if forecast.outcome!="Victory" else ("DANGEROUS" if ratio<0.25 else ("RISKY" if ratio<0.6 else "FAVORABLE"))
  UI.label(content,"Current-state forecast: "+risk)
  UI.label(content,"Based on your current HP, MP, equipment and companion.\nResolution consumes resources and can end in defeat. No rewards on defeat.\nThe forecast does not spend resources.")
  var successes=0
  for index in range(24):
   var sample=State.hero.duplicate(true)
   sample.seed=GameRules.next_seed(int(sample.seed)+index*977)
   var rollout=Combat.new(sample,State.stats(),species)
   rollout.auto_resolve()
   if rollout.outcome=="Victory": successes+=1
  UI.label(content,"Estimated wins: %s / 24 simulated seeds (%.0f%%).\nActual current-seed forecast: %s HP · %s MP · %s potions remaining." % [successes,successes/24.0*100,forecast.h.hp,forecast.h.mp,forecast.h.potions])
  if offer_normal:
   UI.button(content,"Fight normally",func():
    close()
    fight_requested.emit())
  UI.button(content,"Auto-Battle · resolve with these resources",resolve)
 UI.button(content,"Back",close)
func resolve():
 if not active or resolved: return
 var wins=State.species_wins(species)
 if species in ["warden","reliquary_keeper","glass_sentinel","ironroot_colossus"] or wins<10: return
 resolved=true
 var hp=int(State.hero.hp)
 var mp=int(State.hero.mp)
 var supplies:Dictionary=State.hero.items.duplicate(true)
 var potions=int(State.hero.potions)
 var gold=int(State.hero.gold)
 var level=int(State.hero.level)
 var sim=Combat.new(State.hero,State.stats(),species)
 sim.auto_resolve()
 State.hero=sim.h
 if sim.outcome=="Victory":
  State.reward(false,species)
  State.record_encounter_clear()
 else:
  State.retreat_to_safety()
 State.save_game()
 clear()
 UI.label(content,"AUTO-BATTLE / "+sim.outcome.to_upper()).add_theme_font_size_override("font_size",25)
 UI.label(content,"%s rounds · HP %s → %s · MP %s → %s\nPotions %s → %s · Companion HP %s\nGold +%s · Level %s → %s" % [sim.turns,hp,State.hero.hp,mp,State.hero.mp,potions,State.hero.potions,sim.wolf_hp,State.hero.gold-gold,level,State.hero.level])
 UI.label(content,"+%s XP · normal item-drop roll applied.\nOnly normal victories count toward species mastery." % sim.enemy.xp if sim.outcome=="Victory" else "No rewards. Return to camp and rest before trying again.")
 if sim.outcome=="Victory" and int(State.last_reward.get("bonus",0))>0: UI.label(content,"Dexterity bonus included: +%s gold." % State.last_reward.bonus)
 var spent=[]
 for id in ["ether","elixir","treat"]:
  var count=int(supplies.get(id,0))-int(State.hero.items.get(id,0))
  if count>0:spent.append("%s ×%s" % [InventoryBook.data[id].name,count])
 if not spent.is_empty():UI.label(content,"Supplies spent: "+", ".join(spent))
 UI.button(content,"Return to exploration",close)
func close():
 active=false
 if is_instance_valid(shade): shade.hide()
 if is_instance_valid(content): content.get_parent().get_parent().hide()
 closed.emit()
func _input(event):
 if active and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  get_viewport().set_input_as_handled()
  close()

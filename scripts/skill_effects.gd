class_name SkillEffects
extends RefCounted
# Shared by manual combat and auto-battle. All randomness uses the combat seed.
const COLORS={"fire":"f3a367","ice":"91dbe9","holy":"ffe5a1","shadow":"b59ade","nature":"9cdb86","arcane":"a1b7ff","lightning":"e7dc76","wind":"a1e4d5","physical":"e4bc89","sonic":"e9bd8e"}
static func conditional(sim,entry:Dictionary)->bool:
 match entry.get("conditional",""):
  "afflicted":return sim.marked>0 or sim.poison>0 or sim.wound_rounds>0 or sim.burn_rounds>0
  "weakened":return sim.weakened>0 or sim.sunder_rounds>0
  "low_hp":return sim.enemy_hp<float(sim.enemy.hp)*.35
  "healthy":return sim.enemy_hp>float(sim.enemy.hp)*.7
 return false
static func cast(sim,action:String,entry:Dictionary,power:int):
 var magic=entry.get("damage_type","physical")!="physical" and entry.kind in ["spell","mythic"]
 if entry.get("scaling","")=="voice":power=int(entry.power)+int(sim.h.level)*1.5
 if magic and entry.get("scaling","")!="voice":power=int(entry.power)+int(sim.stats.max_mp)*.18+int(sim.h.level)*1.5
 if conditional(sim,entry):power+=int(entry.get("conditional_bonus",0))
 if entry.get("self_damage",0)>0:sim.h.hp=maxi(1,int(sim.h.hp)-int(entry.self_damage))
 var count=int(entry.get("hits",1))
 var landed=false
 var before=sim.enemy_hp
 for i in count:
  if sim.enemy_hp<=0:break
  if sim.hit_enemy("Hero",int(power*float(entry.get("hit_scale",1.0))),action):landed=true
 if landed:
  if float(entry.get("execute_chance",0))>0:
   if sim.enemy.get("boss",false):sim.emit("Hero","Goblin",0,"Deathmark · boss immune to instant KO")
   elif sim.rng.randf()<float(entry.execute_chance):
    var remaining=sim.enemy_hp
    sim.enemy_hp=0
    sim.emit("Hero","Goblin",remaining,"Deathmark · instant KO!")
  if entry.get("sunder",0)>0:
   sim.sunder=int(entry.sunder);sim.sunder_rounds=int(entry.get("duration",3))+1
   sim.emit("Hero","Goblin",0,"Armor break · defense -%s" % sim.sunder)
  if entry.get("burn",0)>0:sim.burn=int(entry.burn);sim.burn_rounds=int(entry.get("duration",3))
  if entry.get("wound",0)>0:sim.wound=int(entry.wound);sim.wound_rounds=int(entry.get("duration",3))
  var resist=.5 if sim.enemy.get("boss",false) else 1.0
  if entry.has("stun_chance") and sim.rng.randf()<float(entry.stun_chance)*resist:sim.enemy_stun=1;sim.emit("Hero","Goblin",0,"Stunned for one turn")
  if entry.has("root_chance") and sim.rng.randf()<float(entry.root_chance)*resist:sim.bound=1;sim.emit("Hero","Goblin",0,"Rooted for one turn")
  if entry.has("mp_drain"):
   var amount=mini(int(entry.mp_drain),int(sim.stats.max_mp)-int(sim.h.mp))
   sim.h.mp+=amount;sim.emit("Hero","Hero",0,"Siphon · MP +%s" % amount)
  if entry.has("life_steal"):sim.heal(int((before-sim.enemy_hp)*float(entry.life_steal)),action+" · leech")
 after(sim,entry,action)
static func after(sim,entry:Dictionary,action:String):
 if entry.get("smite_undead",0)>0 and sim.enemy.get("tags",[]).has("undead"):sim.hit_enemy("Hero",int(entry.smite_undead),action)
 if sim.h.companion.active:
  var record:Dictionary=sim.h.companion.get("records",{}).get(sim.h.companion.get("current","intro_wolf"),{})
  var max_pet=55 if sim.h.companion.current=="intro_wolf" else int(CompanionRules.data.get(sim.h.companion.current,{"hp":55}).hp)+int(record.get("level",1))*3+CompanionRules.pet_bonus(sim.h,"max_hp")
  if entry.get("pet_revive",false):
   var was_down=sim.wolf_hp<=0
   var amount=mini(55,maxi(0,max_pet-sim.wolf_hp));sim.wolf_hp+=amount
   sim.emit("Hero","Wolf",-amount,action+" · companion revived" if was_down else action+" · companion restored")
  elif entry.get("pet_heal",0)>0 and sim.wolf_hp>0:
   var healed=mini(int(entry.pet_heal),maxi(0,max_pet-sim.wolf_hp))
   sim.wolf_hp+=healed;sim.emit("Hero","Wolf",-healed,action+" · companion restored")
 for pair in [["ward","defense"],["evasion","dexterity"]]:
  if entry.has(pair[0]):
   sim.buffs[pair[1]]={"amount":int(entry[pair[0]]),"rounds":int(entry.get("duration",3))+1}
   sim.emit("Hero","Hero",0,action+" · "+pair[1]+" increased")
static func tooltip(value:String)->String:
 var e=AbilityBook.entry(value)
 if e.is_empty():return ""
 var requirements="\nRequired weapons: "+", ".join(e.weapon_types) if not e.get("weapon_types",[]).is_empty() else ""
 return "%s · %s MP\n%s%s" % [e.name,e.mp,e.description,requirements]

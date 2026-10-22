extends Node
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
 checks += 1
 if ok:
  print("PASS: " + label)
 else:
  failures += 1
  push_error("FAIL: " + label)

func _ready() -> void:
 call_deferred("run")

func run() -> void:
 var catalog = CampaignCatalog.load_data()
 check(CampaignCatalog.validate(catalog).is_empty(), "Campaign catalog has valid regions, towns, and dungeons")
 check(catalog.dungeons.size() == 12, "Twelve major dungeons registered")
 check(ResourceLoader.exists("res://scenes/mirefen.tscn"), "Mirefen scene present")
 check(ResourceLoader.exists("res://scenes/reliquary.tscn"), "Reliquary scene present")
 State.new_adventure()
 State.create_hero("Tester", "Wizard", 0, 0, 0, ["Ranger", "Monk"])
 State.hero.journey.finished = true
 State.hero.journey.region = "mirefen"
 State.remember_position(Vector3(0, 0, -22))
 check(State.travel_scene() == "res://scenes/mirefen.tscn", "Mirefen travel routes to its scene")
 State.hero.campaign = {"reliquary_west": true, "reliquary_east": false, "reliquary_cleared": false}
 check(State.save_game(), "Expanded campaign state saves")
 State.reset()
 State.load_game()
 check(State.hero.campaign.reliquary_west and not State.hero.campaign.reliquary_east, "Partial floodgate progress persists")
 check(State.hero.primary == "Wizard" and State.hero.secondary == ["Ranger", "Monk"], "Chosen classes remain intact")
 check(State.hero.journey.region == "mirefen", "Marsh region remains active")
 State.hero.journey.region = "reliquary"
 check(State.travel_scene() == "res://scenes/reliquary.tscn", "Reliquary travel routes correctly")
 var mobs = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
 check(mobs.has("reliquary_keeper"), "Relic keeper enemy data exists")
 check(mobs.reliquary_keeper.get("model") == "Mossling", "Relic keeper uses existing compatible visual")
 State.hero.campaign.reliquary_cleared = true
 check(State.save_game(), "Boss completion flag saves")
 State.reset()
 State.load_game()
 check(State.hero.campaign.reliquary_cleared, "Boss completion flag reloads")
 print("Campaign expansion checks: %s / failed: %s" % [checks, failures])
 get_tree().quit.call_deferred(1 if failures else 0)

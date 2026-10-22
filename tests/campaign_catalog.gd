extends SceneTree

func _initialize() -> void:
 var catalog := CampaignCatalog.load_data()
 var issues := CampaignCatalog.validate(catalog)
 if issues.size() > 0:
  for issue in issues:
   push_error(issue)
  quit(1)
  return
 assert(catalog.dungeons.size() == 12)
 assert(CampaignCatalog.dungeon("dungeon_1").existing_scene == "res://scenes/dungeon.tscn")
 assert(CampaignCatalog.dungeon("dungeon_12").branch_options.human_crown.final_boss_id == "vaelor")
 assert(CampaignCatalog.dungeon("dungeon_12").branch_options.demon_throne.final_boss_id == "aldren")
 print("PASS: 12 dungeon/region/shop campaign catalog validated")
 quit(0)

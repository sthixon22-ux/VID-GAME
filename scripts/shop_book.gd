class_name ShopBook
extends RefCounted
static var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/shops.json"))
static func stock(shop_id:String="willowbrook")->Array:
 return data.get(shop_id,{}).get("equipment",[])
static func in_stock(item:String,shop_id:String="willowbrook")->bool:
 return stock(shop_id).has(item)

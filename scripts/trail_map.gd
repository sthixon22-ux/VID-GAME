class_name TrailMap
extends Control
var hero_position=Vector3.ZERO
var dungeon=false
var markers:Array=[]
var floor_cells:Dictionary={}
func point(pos:Vector3)->Vector2:
 if State.hero.journey.region in ["mirefen","reliquary"]:return Vector2(105+pos.x*4,32+(pos.z+67)/80.0*142)
 if dungeon: return Vector2(105+pos.x*5,170+pos.z*4.2)
 return Vector2(12+(pos.x+28)/108.0*186,12+(pos.z+82)/100.0*166)
func _draw():
 draw_style_box(frame(),Rect2(Vector2.ZERO,size))
 if State.hero.journey.region in ["mirefen","reliquary"]:
  draw_rect(Rect2(24,23,162,151),Color("365c60"))
  draw_line(point(Vector3(0,0,8)),point(Vector3(0,0,-62)),Color("b7ad8b"),7)
  for z in [-5,-12]:
   for x in [-8,8]:draw_rect(Rect2(point(Vector3(x,0,z))-Vector2(7,5),Vector2(14,10)),Color("a28a64"))
 elif dungeon:
  for cell in floor_cells:
   draw_rect(Rect2(point(Vector3(cell.x*2,0,cell.y*2))-Vector2(5,4),Vector2(10,8)),Color("627678"))
 else:
  draw_rect(Rect2(12,125,81,50),Color("665e4b"))
  draw_rect(Rect2(12,12,81,113),Color("344d42"))
  draw_rect(Rect2(93,12,105,113),Color("777648"))
  var route=PackedVector2Array()
  for pos in Forest.ROUTE: route.append(point(pos))
  draw_polyline(route,Color("c7b88a"),2,true)
 for marker in markers:
  draw_circle(point(marker.position),3,marker.color)
 draw_circle(point(hero_position),5,Color("fff0bd"))
 draw_arc(point(hero_position),7,0,TAU,20,Color("182b33"),2,true)
 draw_string(ThemeDB.fallback_font,Vector2(13,18),"SUNKEN RELIQUARY" if State.hero.journey.region=="reliquary" else ("N · MIREFEN CAUSEWAY" if State.hero.journey.region=="mirefen" else ("SANCTUARY" if dungeon else "N · WILLOWBROOK TRAIL")),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f4e9d2"))
func frame()->StyleBoxFlat:
 var style=StyleBoxFlat.new()
 style.bg_color=Color(0.04,0.07,0.09,0.88)
 style.border_color=Color("aa9873")
 style.set_border_width_all(1)
 style.set_corner_radius_all(12)
 return style

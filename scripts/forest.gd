class_name Forest
extends RefCounted
const SHRINE=Vector3(64,0,-60)
const ROUTE=[Vector3(0,0,5),Vector3(0,0,-20),Vector3(-5,0,-40),Vector3(8,0,-54),Vector3(40,0,-54),SHRINE]
const CRYSTALS=[Vector3(28,0,-47),Vector3(44,0,-66),Vector3(57,0,-46)]
const QUEST_NPCS=[Vector3(-5,0,8),Vector3(8,0,9),Vector3(-11,0,0)]
var obstacles:Array[Vector3]=[]
var herbs:Array[Node3D]=[]
var crystals:Array[Node3D]=[]
var herb_positions=[Vector3(-7,0,-25),Vector3(-9,0,-43),Vector3(35,0,-57)]
func near_route(pos:Vector3,radius:float)->bool:
 for i in range(ROUTE.size()-1):
  var a:Vector3=ROUTE[i]
  var b:Vector3=ROUTE[i+1]
  if pos.distance_to(Geometry3D.get_closest_point_to_segment(pos,a,b))<radius: return true
 return false
func build(root:Node3D):
 Art.environment_(root)
 # Broad meadow and woodland floors, with winding dirt rather than bright disc paths.
 var plains=Art.box(root,Vector3(48,-0.12,-54),Vector3(62,0.2,53),Color("84905e"))
 plains.material_override=Art.surface(Color("aaa77c"),"grass",24)
 for index in range(ROUTE.size()-1):
  var a:Vector3=ROUTE[index]
  var b:Vector3=ROUTE[index+1]
  for i in range(ceil(a.distance_to(b)*1.4)+1):
   var point=a.lerp(b,float(i)/maxf(1,ceil(a.distance_to(b)*1.4)))
   var path=Art.shape(root,point+Vector3(0,0.016,0),Vector3(3.1,0.025,3.1),Color("867855"),"cylinder")
   path.material_override=Art.surface(Color("b3a480"),"dirt",1.5)
 var water=Art.box(root,Vector3(18,0.04,-49),Vector3(3.0,0.06,62),Color("446b76"))
 var water_material=ShaderMaterial.new()
 water_material.shader=load("res://assets/shaders/water.gdshader")
 water.material_override=water_material
 for i in range(13):
  Art.box(root,Vector3(15.8+i*0.37,0.18,-54),Vector3(0.33,0.24,3.4),Color("8b7255")).material_override=Art.surface(Color("ad9876"),"wood",2)
 for z in [-55.6,-52.4]:
  Art.box(root,Vector3(18,0.9,z),Vector3(5.2,0.12,0.13),Color("6f5945"))
  for x in [15.5,18,20.5]: Art.box(root,Vector3(x,0.55,z),Vector3(0.16,1.1,0.16),Color("6f5945"))
 for pos in [Vector3(-8,0,5),Vector3(7,0,5),Vector3(-9,0,-4),Vector3(8,0,-5),Vector3(-11,0,12),Vector3(12,0,12)]:
  VillageArt.cottage(root,pos)
  obstacles.append(Vector3(pos.x,2.65,pos.z))
 Art.sign_(root,Vector3(0,3,-14),"WILLOWBROOK\nWoodland road · north")
 for x in [-3.2,3.2]:
  Art.shape(root,Vector3(x,1.7,-14),Vector3(0.5,3.4,0.5),Color("60675c"),"cylinder").material_override=Art.surface(Color("a5aa96"),"stone",2)
 for x in [-15,-11,-7,7,11,15]:
  Art.box(root,Vector3(x,0.65,-13),Vector3(3.6,1.3,0.25),Color("75624b")).material_override=Art.surface(Color("ab9778"),"wood",3)
 var merchant=Art.actor("Mira")
 root.add_child(merchant)
 merchant.position=Vector3(3.5,0,1)
 Art.box(root,Vector3(3.5,0.45,0),Vector3(1.6,0.9,0.7),Color("856341"))
 Art.sign_(root,Vector3(3.5,2.8,1),"Outfitter")
 Art.box(root,Vector3(0,1.2,5),Vector3(1.8,1.3,0.15),Color("856341"))
 Art.sign_(root,Vector3(0,2.6,5),"Village board")
 var mira=Art.actor("Mira")
 root.add_child(mira)
 mira.position=Vector3(-2.6,0,-0.8)
 Art.sign_(mira,Vector3(0,2.6,0),"Mira · Herbalist")
 for i in range(8):
  var angle=i*TAU/8
  Art.shape(root,Vector3(sin(angle)*0.7,0.12,cos(angle)*0.7+2),Vector3(0.36,0.24,0.36),Color("777b70"))
 Art.shape(root,Vector3(0,0.45,2),Vector3(0.45,0.7,0.45),Color("dc995d"),"cone")
 var fire=OmniLight3D.new()
 fire.position=Vector3(0,1,2)
 fire.light_color=Color("ffbc69")
 fire.omni_range=5
 root.add_child(fire)
 for index in range(3):
  var npc=Art.actor("Mira")
  root.add_child(npc)
  npc.position=QUEST_NPCS[index]
  var id: String=QuestBook.data.keys()[index]
  Art.sign_(npc,Vector3(0,2.6,0),QuestBook.data[id].giver)
 # Shrine sits beyond the meadow, backed by ruined stone terraces.
 Art.shape(root,SHRINE+Vector3(0,0.12,0),Vector3(9,0.24,9),Color("91988a"),"cylinder").material_override=Art.surface(Color("b0b5a4"),"stone",3)
 for x in [-3,3]:
  for z in [-3,3]:
   Art.shape(root,SHRINE+Vector3(x,1.8,z),Vector3(0.7,3.6,0.7),Color("a9afa0"),"cylinder").material_override=Art.surface(Color("bec0ac"),"stone",2)
 Art.box(root,SHRINE+Vector3(0,3.7,-3),Vector3(7.2,0.5,1),Color("a4ac99")).material_override=Art.surface(Color("b4bba6"),"stone",2)
 Art.shape(root,SHRINE+Vector3(0,1,0),Vector3(0.7,1.6,0.7),Color("72b7ab"),"cone")
 Art.sign_(root,SHRINE+Vector3(0,4.5,0),"Verdant Shrine\nRootbound Sanctuary below")
 for pos in herb_positions:
  var herb=Node3D.new()
  root.add_child(herb)
  herb.position=pos
  for i in range(5):
   Art.shape(herb,Vector3(sin(i*2)*0.23,0.3,cos(i*2)*0.23),Vector3(0.16,0.6,0.16),Color("64844f"),"cone")
   Art.shape(herb,Vector3(sin(i*2)*0.23,0.6,cos(i*2)*0.23),Vector3(0.15,0.18,0.15),Color("ad83b0"))
  Art.sign_(herb,Vector3(0,1.3,0),"Moonleaf")
  herbs.append(herb)
 for pos in CRYSTALS:
  var crystal=Node3D.new()
  root.add_child(crystal)
  crystal.position=pos
  for i in range(4):
   var shard=Art.shape(crystal,Vector3(sin(i*2)*0.25,0.3,cos(i*2)*0.25),Vector3(0.25,0.7,0.25),Color("79aebd"),"cone")
   shard.rotation.z=sin(i)*0.3
  Art.sign_(crystal,Vector3(0,1.5,0),"Skyglass")
  crystals.append(crystal)
 var rng=RandomNumberGenerator.new()
 rng.seed=821
 for i in range(210):
  var pos=Vector3(rng.randf_range(-26,76),0,rng.randf_range(-80,17))
  if pos.z> -16 and pos.x<20: continue
  if pos.x>20 and i%6!=0: continue
  if near_route(pos,4) or absf(pos.x-18)<3: continue
  if pos.distance_to(SHRINE)<8: continue
  var safe=true
  for plant in herb_positions+CRYSTALS:
   if pos.distance_to(plant)<3.2: safe=false
  if not safe: continue
  Art.tree(root,pos,rng.randf_range(0.8,1.65))
  obstacles.append(Vector3(pos.x,0.6,pos.z))
 for i in range(180):
  var pos=Vector3(rng.randf_range(-26,76),0,rng.randf_range(-80,-17))
  if near_route(pos,2) or absf(pos.x-18)<2: continue
  if i%4==0:
   var rock=Art.shape(root,pos+Vector3(0,0.2,0),Vector3(0.8,0.65,0.7),Color("6f776d"))
   rock.material_override=Art.surface(Color("a3aaa0"),"stone",1)
  else:
   for blade in range(3):
    var tuft=Art.shape(root,pos+Vector3(blade*0.12,0.2,0),Vector3(0.09,0.65,0.16),Color("728256"),"cone")
    tuft.rotation.z=(blade-1)*0.3
 # Continuous, layered ridgelines replace the old round backdrop hills.
 for layer in range(3):
  var surface=SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  var points:Array[Vector3]=[]
  for index in range(129):
   var angle=index*TAU/128
   var radius=102.0+layer*24
   var height=12+layer*5+sin(angle*5+.7)*5+sin(angle*11+layer)*2.5
   points.append(Vector3(25+sin(angle)*radius,height,-32+cos(angle)*radius))
  for index in range(128):
   var a:Vector3=points[index]
   var b:Vector3=points[index+1]
   for vertex in [Vector3(a.x,-8,a.z),a,b,Vector3(a.x,-8,a.z),b,Vector3(b.x,-8,b.z)]:surface.add_vertex(vertex)
  surface.generate_normals()
  var ridge=MeshInstance3D.new()
  ridge.mesh=surface.commit()
  var material=StandardMaterial3D.new()
  material.albedo_color=[Color("647b72"),Color("82978a"),Color("a1b2a0")][layer]
  material.cull_mode=BaseMaterial3D.CULL_DISABLED
  material.roughness=1
  ridge.material_override=material
  root.add_child(ridge)
func can_walk(pos:Vector3)->bool:
 if pos.x< -27 or pos.x>78 or pos.z< -81 or pos.z>17: return false
 if pos.z> -31 and pos.x>18: return false
 if absf(pos.x-18)<1.8 and absf(pos.z+54)>1.4: return false
 for obstacle in obstacles:
  if Vector2(pos.x-obstacle.x,pos.z-obstacle.z).length()<obstacle.y+0.3: return false
 return true
static func region(pos:Vector3)->String:
 if pos.z> -16: return "Willowbrook Village"
 if pos.x<19: return "Whisperwood"
 return "Sunmeadow Plains" if pos.distance_to(SHRINE)>9 else "Verdant Shrine"

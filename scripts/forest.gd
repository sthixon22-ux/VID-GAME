class_name Forest
extends RefCounted
var obstacles: Array[Vector3]=[]
var herbs: Array[Node3D]=[]
var herb_positions=[Vector3(-6,0,-8),Vector3(7,0,-17),Vector3(20,0,-16)]
func build(root: Node3D):
 Art.environment_(root)
 # Paths are overlapping low-sided discs, linking distinct authored destinations.
 for segment in [[Vector3(0,0,2),Vector3(0,0,-12)],[Vector3(0,0,-12),Vector3(24,0,-12)],[Vector3(0,0,0),Vector3(-9,0,4)]]:
  for i in range(24):
   var point: Vector3=segment[0].lerp(segment[1],i/23.0)
   Art.shape(root,point+Vector3(0,0.015,0),Vector3(3.6,0.04,3.6),Color("aa9a65"),"cylinder")
 # Stream and a bridge: crossing is restricted to the deck.
 var water=Art.box(root,Vector3(12,0.055,0),Vector3(3.2,0.07,64),Color("579fac"))
 var water_material=ShaderMaterial.new()
 water_material.shader=load("res://assets/shaders/water.gdshader")
 water.material_override=water_material
 for i in range(13):
  Art.box(root,Vector3(9.8+i*0.37,0.21,-12),Vector3(0.33,0.22,3.1),Color("9a714b")).material_override=Art.surface(Color("bd9d72"),"wood",2)
 for z in [-13.5,-10.5]:
  Art.box(root,Vector3(12,0.9,z),Vector3(5.2,0.12,0.13),Color("6f513c"))
  for x in [9.5,12,14.5]: Art.box(root,Vector3(x,0.55,z),Vector3(0.16,1.1,0.16),Color("6f513c"))
 # Village houses, with plaster walls, overhanging roofs and lit windows.
 for pos in [Vector3(-7,0,5),Vector3(6,0,6),Vector3(-8,0,-2)]:
  var house=Node3D.new()
  root.add_child(house)
  house.position=pos
  Art.box(house,Vector3(0,1.25,0),Vector3(3.7,2.5,3.2),Color("dfc49a")).material_override=Art.surface(Color("f3dcaf"),"stone",2)
  for side in [-1,1]:
   var roof=Art.box(house,Vector3(side*1.05,2.85,0),Vector3(2.5,0.22,4.0),Color("8f514f"))
   roof.rotation.z=side*-0.5
   roof.material_override=Art.surface(Color("b27669"),"tile",3)
  Art.box(house,Vector3(0,0.9,-1.65),Vector3(0.85,1.8,0.12),Color("725237"))
  for x in [-1.1,1.1]: Art.box(house,Vector3(x,1.5,-1.65),Vector3(0.6,0.65,0.1),Color("f4d990"))
  Art.box(house,Vector3(1.15,3.1,0.7),Vector3(0.5,1.3,0.5),Color("a39a86"))
  obstacles.append(Vector3(pos.x,2.65,pos.z))
 Art.sign_(root,Vector3(-3,1.8,7),"Willowbrook")
 # Campfire, seats, villager and a route marker.
 for i in range(8):
  var angle=i*TAU/8
  Art.shape(root,Vector3(sin(angle)*0.7,0.15,cos(angle)*0.7+2),Vector3(0.36,0.3,0.36),Color("8e9488"))
 Art.shape(root,Vector3(0,0.45,2),Vector3(0.6,0.9,0.6),Color("f5a34b"),"cone")
 var fire=OmniLight3D.new()
 fire.position=Vector3(0,1,2)
 fire.light_color=Color("ffbc69")
 fire.omni_range=5
 root.add_child(fire)
 for x in [-2,2]: Art.box(root,Vector3(x,0.3,2),Vector3(0.6,0.6,1.7),Color("816343"))
 var villager=Art.actor("Mira",{"Chest":"Leather Vest","Shield":"None"})
 root.add_child(villager)
 villager.position=Vector3(-2.6,0,-0.8)
 Art.sign_(root,Vector3(-2.6,2.8,-0.8),"Mira · Herbalist\n[E] Talk")
 Art.sign_(root,Vector3(2,1.5,-5),"→ Sunstream bridge\n↑ Woodland trail")
 # Ruined shrine destination across the stream.
 Art.shape(root,Vector3(24,0.15,-12),Vector3(7,0.3,7),Color("a4ac9b"),"cylinder")
 for x in [21.5,26.5]:
  for z in [-14.5,-9.5]:
   Art.shape(root,Vector3(x,1.5,z),Vector3(0.65,3,0.65),Color("c4c7af"),"cylinder")
 Art.box(root,Vector3(24,3.1,-14.5),Vector3(6,0.5,0.9),Color("aeb6a3"))
 Art.shape(root,Vector3(24,1.1,-12),Vector3(0.8,1.7,0.8),Color("82cfbc"),"cone")
 Art.sign_(root,Vector3(24,4,-12),"THE VERDANT SHRINE\n[E] Discover")
 for pos in herb_positions:
  var herb=Node3D.new()
  root.add_child(herb)
  herb.position=pos
  for i in range(3):
   Art.shape(herb,Vector3(sin(i*2)*0.23,0.3,cos(i*2)*0.23),Vector3(0.22,0.65,0.22),Color("9dc85e"),"cone")
   Art.shape(herb,Vector3(sin(i*2)*0.23,0.65,cos(i*2)*0.23),Vector3(0.2,0.2,0.2),Color("d5a3d8"))
  Art.sign_(herb,Vector3(0,1.3,0),"Moonleaf · [E]")
  herbs.append(herb)
 # Deterministic forest dressing. Leave village, bridge and trail clear.
 var rng=RandomNumberGenerator.new()
 rng.seed=821
 for i in range(115):
  var pos=Vector3(rng.randf_range(-31,31),0,rng.randf_range(-30,29))
  if pos.z> -6 and absf(pos.x)<12: continue
  if absf(pos.x)<3 or absf(pos.z+12)<3 or absf(pos.x-12)<3: continue
  if pos.distance_to(Vector3(24,0,-12))<6: continue
  Art.tree(root,pos,rng.randf_range(0.8,1.4))
  obstacles.append(Vector3(pos.x,0.7,pos.z))
 for i in range(90):
  var pos=Vector3(rng.randf_range(-30,30),0,rng.randf_range(-29,28))
  if absf(pos.x-12)<2 or absf(pos.x)<2 or absf(pos.z+12)<2: continue
  if pos.z> -6 and absf(pos.x)<12: continue
  Art.shape(root,pos+Vector3(0,0.14,0),Vector3(0.25,0.45,0.25),Color("719c50"),"cone")
  if i%3==0: Art.shape(root,pos+Vector3(0,0.4,0),Vector3(0.15,0.15,0.15),Color("e8ce7c"))
 for i in range(16):
  var angle=i*TAU/16
  Art.shape(root,Vector3(sin(angle)*47,-1,cos(angle)*47),Vector3(18,12+i%4*2,18),Color("759478"))
func can_walk(pos: Vector3) -> bool:
 if absf(pos.x)>31 or absf(pos.z)>29: return false
 if absf(pos.x-12)<1.9 and absf(pos.z+12)>1.25: return false
 for obstacle in obstacles:
  if Vector2(pos.x-obstacle.x,pos.z-obstacle.z).length()<obstacle.y+0.3: return false
 return true

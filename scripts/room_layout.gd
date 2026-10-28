class_name RoomLayout
extends RefCounted
static func rect(cells:Dictionary,x0:int,x1:int,z0:int,z1:int):
 for x in range(x0,x1+1):
  for z in range(z0,z1+1):cells[Vector2i(x,z)]=true
static func expedition()->Dictionary:
 var cells={}
 # Six rooms joined by offset halls; side rooms contain mandatory puzzles and optional vaults.
 rect(cells,-3,3,-3,3)
 rect(cells,-12,-6,-3,3)
 rect(cells,-9,-1,-1,1)
 rect(cells,-2,2,-10,-2)
 rect(cells,-3,3,-12,-6)
 rect(cells,1,9,-10,-8)
 rect(cells,6,12,-12,-6)
 rect(cells,-10,-2,-10,-8)
 rect(cells,-10,-8,-19,-8)
 rect(cells,-12,-6,-21,-15)
 rect(cells,-1,1,-16,-10)
 rect(cells,-4,4,-22,-15)
 return cells
static func contains(cells:Dictionary,p:Vector3)->bool:
 return cells.has(Vector2i(floori((p.x+1)/2),floori((p.z+1)/2)))
static func build(root:Node3D,cells:Dictionary,color_:Color):
 var floor_mat=Art.surface(color_,"stone",1)
 var wall_mat=Art.surface(color_.lightened(.12),"stone",1)
 for cell in cells:
  var point=Vector3(cell.x*2,0,cell.y*2)
  Art.box(root,point+Vector3(0,-.15,0),Vector3(2,.3,2),Color.WHITE).material_override=floor_mat
  for edge in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   if cells.has(cell+edge):continue
   var height=1.25 if edge==Vector2i.DOWN else 2.8
   var size_=Vector3(.2 if edge.x else 2.1,height,.2 if edge.y else 2.1)
   var wall=Art.box(root,point+Vector3(edge.x,height/2,edge.y),size_,Color.WHITE)
   wall.material_override=wall_mat
   CameraObstacles.box(root,wall.position,size_)

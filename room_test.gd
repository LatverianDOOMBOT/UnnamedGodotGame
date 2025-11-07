extends Node3D

var rng = RandomNumberGenerator.new()

#Мързи ме да изкоментирам целия код. Имплементация на Breadth-First Search съм правил самостоятелно преди, ама ме домързя да се занимавам с map generation
#Казах на claude да го направи, нз въобще то какво е направило ама надяваме се да е добро. Само се погрижих да поставя играча в валидна стая/пространство, а не във стена. CollisionShapes няма.
#Бъгът, който се беше проявил последно, не мисля че е бил от моя код. Направих нова сцена/ниво, в което поставих същия код за map gen както и за играч, и нещата се оправиха. Предполагам е било
#Бъг с GridMap node-а, който използвах, когато се опитвах да си измисля свой алгоритъм(голяма грешка, от моя страна). Този map gen ще бъде тежко модифициран. Използвам shader за edge detection(затова всичко е бяло и стените имат черни ръбове), и съм
#Поставил някакъв 3D модел в ъгъла на картата, за да видя дали, ако му е приложен cross hatch shader, ще изглежда все едно е нарисуван в комиксов стил. Не се получава много добре, но ¯\_(ツ)_/¯
#Сравнение трябва да има с картинката, която бях вкарал в гейм дизайн док-а. Там беше само с edge detection shader, и предполагам 3Д моделите изглеждаха по добре защото имаха повече ръбове. Повече ръбове - повече outlines, следователно по добре. Та да де. Кубчетата нямат много ръбове, затова изглеждат много мех 
#Тъй че да, да запомня - повече изчистени ръбове и ще го докарам 
#Ще добавя някакви врагове и ще тествам комбат системата която написах в гейм дизайн док-а
#Най-големия проблем спрямо дизайна на комбат системата е как точно ще се "engage-ва", но и това ще се реши.
#Играча се движи с w a s d, и се върти наляво и надясно с <- и ->.


const CELL_SIZE = 4.0
var GRID_WIDTH = rng.randi_range(20, 50)
var GRID_HEIGHT = rng.randi_range(20, 50)
var NUM_ROOMS = rng.randi_range(8, 16)
const MIN_ROOM_SIZE = 3
const MAX_ROOM_SIZE = 7
var player = preload("res://player.tscn")


enum CellType { WALL, FLOOR }

var grid = []
var rooms = []

func _ready():
	
	generate_dungeon()
	visualize_dungeon()

func generate_dungeon():
	# Initialize grid with walls
	grid = []
	for x in range(GRID_WIDTH):
		grid.append([])
		for z in range(GRID_HEIGHT):
			grid[x].append(CellType.WALL)
	
	rooms = []
	
	# Place rooms
	for i in range(NUM_ROOMS):
		if i == 1:
			place_random_room(true)
			
		else:
			place_random_room(false)
	
	# Connect all rooms with corridors
	connect_rooms()

func place_random_room(placePlayer : bool):
	var attempts = 0
	while attempts < 50:
		var width = randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var height = randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var x = randi_range(1, GRID_WIDTH - width - 1)
		var z = randi_range(1, GRID_HEIGHT - height - 1)
		
		var new_room = Rect2i(x, z, width, height)
		
		# Check if room overlaps with existing rooms
		var overlaps = false
		for room in rooms:
			if new_room.intersects(room.grow(1)):  # Add 1 cell padding
				overlaps = true
				break
		
		if not overlaps:
			# Carve out the room
			for rx in range(x, x + width):
				for rz in range(z, z + height):
					grid[rx][rz] = CellType.FLOOR
					
			if placePlayer:
				var instance = player.instantiate()
				add_child(instance)
				var spawn_pos = Vector3((new_room.position.x + new_room.size.x / 2.0) * CELL_SIZE, 4, (new_room.position.y + new_room.size.y / 2.0) * CELL_SIZE)
				instance.global_position = spawn_pos
				instance.speed = 16
			
			rooms.append(new_room)
			return
		
		attempts += 1

func connect_rooms():
	# Connect each room to the next one
	for i in range(rooms.size() - 1):
		var room_a = rooms[i]
		var room_b = rooms[i + 1]
		
		# Get centers of both rooms
		var center_a = Vector2i(
			room_a.position.x + room_a.size.x / 2,
			room_a.position.y + room_a.size.y / 2
		)
		var center_b = Vector2i(
			room_b.position.x + room_b.size.x / 2,
			room_b.position.y + room_b.size.y / 2
		)
		
		# Create L-shaped corridor
		if randi() % 2 == 0:
			# Horizontal then vertical
			create_horizontal_corridor(center_a.x, center_b.x, center_a.y)
			create_vertical_corridor(center_a.y, center_b.y, center_b.x)
		else:
			# Vertical then horizontal
			create_vertical_corridor(center_a.y, center_b.y, center_a.x)
			create_horizontal_corridor(center_a.x, center_b.x, center_b.y)

func create_horizontal_corridor(x1: int, x2: int, z: int):
	var start_x = mini(x1, x2)
	var end_x = maxi(x1, x2)
	
	for x in range(start_x, end_x + 1):
		if x >= 0 and x < GRID_WIDTH and z >= 0 and z < GRID_HEIGHT:
			grid[x][z] = CellType.FLOOR
			# Make corridor 2 cells wide for better flow
			if z + 1 < GRID_HEIGHT:
				grid[x][z + 1] = CellType.FLOOR

func create_vertical_corridor(z1: int, z2: int, x: int):
	var start_z = mini(z1, z2)
	var end_z = maxi(z1, z2)
	
	for z in range(start_z, end_z + 1):
		if x >= 0 and x < GRID_WIDTH and z >= 0 and z < GRID_HEIGHT:
			grid[x][z] = CellType.FLOOR
			# Make corridor 2 cells wide for better flow
			if x + 1 < GRID_WIDTH:
				grid[x + 1][z] = CellType.FLOOR

func visualize_dungeon():
	for x in range(GRID_WIDTH):
		for z in range(GRID_HEIGHT):
			if grid[x][z] == CellType.FLOOR:
				create_floor(x, z)
			else:
				create_wall(x, z)

func create_floor(x: int, z: int):
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(CELL_SIZE, 0.2, CELL_SIZE)
	mesh_instance.mesh = box_mesh
	
	# Create material for floor
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.35)
	mesh_instance.material_override = material
	
	mesh_instance.position = Vector3(x * CELL_SIZE, 0, z * CELL_SIZE)
	add_child(mesh_instance)

func create_wall(x: int, z: int):
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(CELL_SIZE, 3, CELL_SIZE)
	mesh_instance.mesh = box_mesh
	
	# Create material for walls
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.4, 0.3)
	mesh_instance.material_override = material
	
	mesh_instance.position = Vector3(x * CELL_SIZE, 1.5, z * CELL_SIZE)
	add_child(mesh_instance)

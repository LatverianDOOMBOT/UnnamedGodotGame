extends Node3D

@onready var griddy = $GridMap
var rng = RandomNumberGenerator.new()
var roomNumber = randi_range(7, 15)
var mainRouteNum = rng.randi_range(2, 6)
var typeRoom
var roomCords 
var astar_grid = AStarGrid2D.new()
var usedCoords = []
var genCoord : Vector3i
var entrance : Vector3i
var exit : Vector3i
var placed = 0
var exits = {3 : Vector3i(1, 0, 1), 4: Vector3i(0, 0, 1), 5 : Vector3i(1, 0, 0)}
var typeRoomDict = {3 : [], 4: [], 5: []}
var mainRoute : Array
var room : Array

func _ready():
	entrance = Vector3i(0, 0, 0)
	exit = Vector3i(1, 0, 60)
	usedCoords.append(entrance)
	usedCoords.append(exit)
	astar_grid.cell_size = Vector2(2, 2)
	astar_grid.region = Rect2i(0, 0, 60, 60)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	genRooms()
	createMainRoute()
	connectMainRoute()
	
	
func genRooms():
	
	while placed < roomNumber:
		var randomRoomType = rng.randi_range(3, 5)
		roomCords = genRandomVector3i()
		if !usedCoords.has(roomCords):
			usedCoords.append(roomCords)
			typeRoomDict[randomRoomType].append(roomCords)
			placed += 1
			print(typeRoomDict)
			griddy.set_cell_item(typeRoomDict[randomRoomType].back(), randomRoomType)
			
		else:
			continue
			
			
	if placed == roomNumber:
		roomCords = null
		
		
		
func genRandomVector3i():
	var randomVect = Vector3i(rng.randi_range(10, 60), 0, rng.randi_range(10, 60))
	return randomVect
	

func createMainRoute():

	mainRoute.append(entrance)

	var roomMainRoutedKey
	var roomMainRouted
	while mainRoute.size() < mainRouteNum:
		roomMainRoutedKey = rng.randi_range(3, 5)
		if typeRoomDict[roomMainRoutedKey] != null:
			roomMainRouted = typeRoomDict[roomMainRoutedKey].pick_random()
			if roomMainRouted != null:
				mainRoute.append(roomMainRouted)
				typeRoomDict[roomMainRoutedKey].erase(roomMainRouted)
				print("main Route gen: ", mainRoute)
				print("typeRoomDict gen: ", typeRoomDict)
				print("mainRoute size: ", mainRoute.size())
				print("mainRoute Num: ", mainRouteNum)
			
		else:
			continue
		
		
	if mainRoute.size() == mainRouteNum:
		roomMainRoutedKey = null
		roomMainRouted = null
		mainRoute.append(exit)
		
		
		

	
		
		
func connectMainRoute():
	for i in range(mainRoute.size()):
		if i + 1 < mainRoute.size():
			var path = astar_grid.get_id_path(Vector2i(mainRoute[i].x, mainRoute[i].z), Vector2i(mainRoute[i + 1].x, mainRoute[i + 1].z))
			filter_path_with_min_distance(path, 10)
			for cell in range(path.size()):
				griddy.set_cell_item(Vector3i(path[cell].x, 0, path[cell].y), 2)
				astar_grid.set_point_solid(Vector2i(path[cell].x, path[cell].y))
				astar_grid.update()



func filter_path_with_min_distance(path: Array, min_distance: int) -> Array:
	if path.size() <= 2:
		return path
	
	var waypoints = [path[0]] # Start with first point
	var last_waypoint = path[0]
	var current_direction = null
	
	for i in range(1, path.size() - 1):
		var direction = get_direction(path[i - 1], path[i])
		
		# If direction changed and we've traveled minimum distance
		if current_direction != null and direction != current_direction:
			var distance = manhattan_distance(last_waypoint, path[i - 1])
			if distance >= min_distance:
				waypoints.append(path[i - 1])
				last_waypoint = path[i - 1]
		
		current_direction = direction
	
	waypoints.append(path[path.size() - 1]) # Add end point
	
	return fill_path_between_waypoints(waypoints)

func get_direction(from: Vector2i, to: Vector2i) -> Vector2i:
	return Vector2i(sign(to.x - from.x), sign(to.y - from.y))

func manhattan_distance(from: Vector2i, to: Vector2i) -> int:
	return abs(to.x - from.x) + abs(to.y - from.y)

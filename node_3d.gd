extends Node3D

#По едно време се отказах и просто го дадох на Claude, тъй като бях stuck-нат на една много тъпа
#грешка която бях направил.
#И ги е оправил. Кода основния аз съм си го направил, бота реши да си префакторизира нещата(смисъл, промяна на имена на променливи и някакви такива неща)
#Няма драстични промени btw, кода работи по същия начин(генерирането на произволен вектор преди не беше самостоятелна функция, например. Не пречи, пак си бачкаше по същия начин)
#Английските коментари са негови, хванал е някакви неща, които аз не бях хванал.
#Има магически числа btw, те ще бъдат оправени. Целта е да бачка, друго няма значение засега.
#"ОТВОРИ" са входа и изхода в едно(от един отвор в стая може да се излезе и да се влезе)
#Червена стая - два отвора, Лилава стая - три отвора, зелена стая - четири отвора

#Как работи?
#Алгоритъма работи като:
#1. Слагаме стаи произволно, и определяме произволно техния тип.
#1a. стая тип 3 има 2 изхода. Стая тип 4 има 3 изхода. Стая тип 5 има 4 изхода(един за всяка стена)
#1б. Планирам да бъдат поставени на определна дистанция при моделиране, за да могат изходите лесно да се определят(затова се маха от roomCords различни вектори, просто не съм определил константоното разстояние, тъй като нямам готови 3D модели. Не пречи да го определя като константна променлива, но все пак. И най-вече, този .tscn трябва да се използва като отделен node, случва се като му се даде class_name)
#1в. Номера, определящ типа стая е същия, като номера на item-а в meshlibrary-то, което използвам
#1г. Слагаме тези стаи в dictionary typeRoomDict, който е от типа {тип стая(като число): array съдържащ още един array, който от своя страна съдържа Vector3 координати на изходите за една стая}. Сега, това НЕ Е нужно, тъй като и без това ползвам изходите индивидуално ама важното е да сме живи и здрави. Ще го оправя, наистина, но в момента важното е да бачка. Плюс, това не е краят на procedural dungeon generation-а, трябва да се направят още 3 неща - постяването на произволни събития(i.e врагове, pickups и тн), както и украсяването на самите стаи(т.е маси, чаши, и каквото и да е.)
#2. След това правим главен път, определяме случайно колко ще е дълъг(mainRouteNum) като избираме произволно изходи, не цели стаи. Махаме ги от typeRoomDict, и ги слагаме в mainRoute - array, който съдържа изходите
#3. Свързваме главния път, като проверяваме дали са хоризонтално или вертикално подравнени. Ако не, създаваме ъглова точка, за да може да се създаде L-образна фигура от коридори, т.е няма диагонал.
#4. С останалите изходи в typeRoomDict правим branchRoute - слагаме изходите от typeRoomDict в branchRoute. typeRoomDict остава празен, и (май, надявам се на някакво божество) godot си го изчиства.
#5. Така изведнъж имаме един лабиринт в който да се разхождаме.



@onready var griddy = $GridMap #gridmap node-а
var rng = RandomNumberGenerator.new() #random number generator, използван за произволни стойности
var roomNumber = randi_range(7, 20) # Тук се определя колко стаи ще има
var mainRouteNum = rng.randi_range(2, 6) #тука се определя колко стаи ще има в главния път
var branchRoute : Array #това е списъкът, който съдържа branchRoute
var roomCords #ползваме го в генерирането на стаи за да проверим дали вече сме сложили стая там
var astar_grid = AStarGrid2D.new() #алгориътма за намиране на път, godot си има собствена имплементация. Тъй като няма да ползвам y оста(т.е няма да ходи нагоре), използвам двуизмерната опция
var usedCoords = [] #тука запазваме roomCords всеки път като правим стая и гледаме дали новите координати ги има тук. Ако ги има, няма да се генерира стая там
var entrance : Vector3i #hard code-нал съм координатите на входа и изхода
var exit : Vector3i #координатите на изхода
var placed = 0 #стаите, които са поставени. Това се използва в генерирането на стаи
var typeRoomDict = {3 : [], 4: [], 5: []} #речника използван
var mainRoute : Array #списъка използван за главния път
var room : Array

func _ready():
	entrance = Vector3i(0, 0, 0)
	exit = Vector3i(1, 0, 60)
	usedCoords.append(entrance + Vector3i(0, 0, 1))
	usedCoords.append(entrance + Vector3i(1, 0, 1)) #тези изваждания са за задаване на двата отвора(вход/изход) на entrance и exit. Ще го направя по-добре, но засега главния ми проблем е всъщност да направя генерирането на лабиринта
	usedCoords.append(exit - Vector3i(0, 0, 1))
	usedCoords.append(exit - Vector3i(1, 0, 1))
	
	# Initialize A* grid for pathfinding
	astar_grid.cell_size = Vector2(2, 2)
	astar_grid.region = Rect2i(0, 0, 70, 70) #инициализираме grid-а. Отново, не съм вкарал променливи, тъй като не знам колко ще са големи моделите на стаите
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER #задаваме на astar да не ходи по диагонал
	astar_grid.update() #update-ваме а* grid-а
	
	genRooms() #тук се генерират стаите
	createMainRoute() #тук се създава списъка за главния път
	createBranchRoute() #тук се създава списъка за разклоненията
	connectMainRoute() #тук се свързва главния път
	connectBranchRoute() #тук се свързват разклоненията
	
func genRooms():
	while placed < roomNumber: #използваме while loop а не for loop защото има евентуалност usedCoords да има произволно генерираните координати. Дори да му кажем continue, губим един loop и съответно потенциална стая/отвор
		var randomRoomType = rng.randi_range(3, 5)
		roomCords = genRandomVector3i()
		var tempRoomCords
		if !usedCoords.has(roomCords):
			griddy.set_cell_item(roomCords, randomRoomType)
			
			# Mark room as solid in pathfinding grid (no update yet)
			astar_grid.set_point_solid(Vector2i(roomCords.x, roomCords.z))
			match randomRoomType:
				3:
					tempRoomCords = roomCords - Vector3i(0, 0, 1)
					usedCoords.append(tempRoomCords)
					typeRoomDict[randomRoomType].append(tempRoomCords)	#Може да се направи по-добре. В този match(същото като switch в другите езици) се добавят координатите на различните изходи в зависимост от номера на различните изходи
					tempRoomCords = roomCords - Vector3i(1, 0, 0)
					usedCoords.append(tempRoomCords)
					typeRoomDict[randomRoomType].append(tempRoomCords)
					
				
				4:
					tempRoomCords = roomCords - Vector3i(0, 0, 1)
					usedCoords.append(tempRoomCords)
					typeRoomDict[randomRoomType].append(tempRoomCords)
					tempRoomCords = roomCords - Vector3i(1, 0, 0)
					usedCoords.append(roomCords)
					typeRoomDict[randomRoomType].append(tempRoomCords)
					tempRoomCords = roomCords + Vector3i(0, 0, 1)
					usedCoords.append(tempRoomCords)
					typeRoomDict[randomRoomType].append(tempRoomCords)
					
					
				5:
					tempRoomCords = roomCords - Vector3i(0, 0, 1)
					usedCoords.append(tempRoomCords)
					typeRoomDict[randomRoomType].append(tempRoomCords)
					tempRoomCords = roomCords - Vector3i(1, 0, 0)
					usedCoords.append(tempRoomCords)
					typeRoomDict[randomRoomType].append(tempRoomCords)
					tempRoomCords = roomCords + Vector3i(0, 0, 1)
					usedCoords.append(tempRoomCords)
					typeRoomDict[randomRoomType].append(tempRoomCords)
					tempRoomCords = roomCords + Vector3i(1, 0, 0)
					usedCoords.append(tempRoomCords)
					typeRoomDict[randomRoomType].append(tempRoomCords)
					
					
			
			placed += 1
			print("Placed room type ", randomRoomType, " at ", roomCords)
			
			# Place the room in the grid
			
		else:
			continue
	
	# Update A* grid ONCE after all rooms are placed
	astar_grid.update() 
			
	if placed == roomNumber:
		roomCords = null # сетваме го на null за да може godot да си го изчисти
		griddy.set_cell_item(entrance, 0) # не знам защо не съм го сложил това в _ready() но ще го направя по-късно
		griddy.set_cell_item(exit, 1)
		astar_grid.set_point_solid(Vector2i(entrance.x, entrance.z))
		astar_grid.set_point_solid(Vector2i(exit.x, exit.z))
		astar_grid.update()
		
		print("Room generation complete")

func genRandomVector3i():
	var randomVect = Vector3i(rng.randi_range(10, 60), 0, rng.randi_range(10, 60)) #вкарано от Claude като отделна функция, генерира произволни координати
	return randomVect

func createMainRoute():
	mainRoute.append(entrance)
	
	var roomMainRoutedKey
	var roomMainRouted
	var attemptsLimit = 100 #Имаше потенциалност за безкрайни опити, затова съм го сложил това тук.
	var attempts = 0
	
	while mainRoute.size() < mainRouteNum and attempts < attemptsLimit:
		attempts += 1
		roomMainRoutedKey = rng.randi_range(3, 5)
		
		if !typeRoomDict[roomMainRoutedKey].is_empty():
			roomMainRouted = typeRoomDict[roomMainRoutedKey].pick_random() #Избира се на произвол отвор, и след това се маха от речника
			
			if roomMainRouted != null:
				mainRoute.append(roomMainRouted) #имаше потенциал избраната по произвол да бъде null, и аз не помня защо, тъй че го оставям. Добре е за всеки случай да го има
				typeRoomDict[roomMainRoutedKey].erase(roomMainRouted)
				print("Added room to main route: ", roomMainRouted)
	
	mainRoute.append(exit)
	print("Final main route: ", mainRoute)

func createBranchRoute():
	# Flatten the dictionary into a single array of remaining rooms
	var remaining_rooms = [] #тука claude реши да го направи вместо
	for key in typeRoomDict.keys():
		for room in typeRoomDict[key]:
			remaining_rooms.append(room)
	
	# Add all remaining rooms to branch route
	for room in remaining_rooms: #добавяме останалите отвори към разклонения път
		if room != null:
			branchRoute.append(room)
			print("Added room to branch route: ", room)
	
	print("Final branch route: ", branchRoute)
	print("Branch route size: ", branchRoute.size())
	typeRoomDict = null #сетваме речника на null за да си го изчисти godot, сигурно

func connectMainRoute():
	for i in range(mainRoute.size() - 1):
		var start = mainRoute[i]
		var end = mainRoute[i + 1]
		
		var horizontally_aligned = (start.z == end.z)
		var vertically_aligned = (start.x == end.x) #тука проверяваме дали са подравнени хоризонтално или вертикално
		
		if horizontally_aligned or vertically_aligned:
			print("Rooms aligned - connecting directly from ", start, " to ", end)
			connect_two_points(start, end)
		else:
			var horizontal_first = rng.randf() > 0.5 #ако не са, избираме на произвол дали хоризонтала или вертикала да слагаме първо
			var corner_point: Vector3i
			
			if horizontal_first:
				corner_point = Vector3i(end.x, 0, start.z) #ако хоризонтала ти е първата, това е ъгловата точка
			else:
				corner_point = Vector3i(start.x, 0, end.z)
			
			print("Creating L-path: ", start, " -> ", corner_point, " -> ", end)
			connect_two_points(start, corner_point) #създава се L-образна фигура
			connect_two_points(corner_point, end)

func connectBranchRoute():
	for i in range(branchRoute.size() - 1):
		var start = branchRoute[i]
		var end = branchRoute[i + 1] #действа по същия начин като mainRoute
		
		var horizontally_aligned = (start.z == end.z)
		var vertically_aligned = (start.x == end.x)
		
		if horizontally_aligned or vertically_aligned:
			print("Rooms aligned - connecting directly from ", start, " to ", end)
			connect_two_points(start, end)
		else:
			var horizontal_first = rng.randf() > 0.5
			var corner_point: Vector3i
			
			if horizontal_first:
				corner_point = Vector3i(end.x, 0, start.z)
			else:
				corner_point = Vector3i(start.x, 0, end.z)
			
			print("Creating L-path: ", start, " -> ", corner_point, " -> ", end)
			connect_two_points(start, corner_point)
			connect_two_points(corner_point, end)

func connect_two_points(start: Vector3i, end: Vector3i):
	var start_pos = Vector2i(start.x, start.z) #Claude си направи отделна функция за свързване на две точки, моето работеше по същия начин но братлето го е отделило
	var end_pos = Vector2i(end.x, end.z)
	
	# Temporarily unblock start and end points
	var start_was_solid = astar_grid.is_point_solid(start_pos)
	var end_was_solid = astar_grid.is_point_solid(end_pos) #"temporarily unblock" е за да може всъщност да се ходи до там с a*
	
	if start_was_solid:
		astar_grid.set_point_solid(start_pos, false) #тука ги update-ваме, сиреч unblock-ваме
	if end_was_solid:
		astar_grid.set_point_solid(end_pos, false)
	
	# SINGLE update call
	astar_grid.update() #update-ваме grid-а, защото сме променили точки в него
	
	# Find path using A* pathfinding
	var path = astar_grid.get_id_path(start_pos, end_pos)
	
	if path.size() > 0:
		for cell_idx in range(path.size()):
			var cell = path[cell_idx]
			var cell_3d = Vector3i(cell.x, 0, cell.y) #тука си ги слагаме, правим го на Vector3 защото на гридмапа му трябва вектор3
			
			if griddy.get_cell_item(cell_3d) == -1:
				griddy.set_cell_item(cell_3d, 2) #гледаме дали съществува
	else:
		print("Warning: No path found between ", start_pos, " and ", end_pos)
	
	# Restore solid state
	if start_was_solid:
		astar_grid.set_point_solid(start_pos, true) #пак си пишем, че тази точка е заета
	if end_was_solid:
		astar_grid.set_point_solid(end_pos, true)
	
	# SINGLE update call
	astar_grid.update() #и пак update-ваме

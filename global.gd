extends Node

var score: int = 0
var highscore: int = 0
var level: int = 1

const SAVE_FILE = "user://gamedata.save"

func _ready():
	load_score()

func load_score():
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			highscore = file.get_as_text().to_int()
			file.close()
	else:
		highscore = 0

func save_score():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(str(highscore))
		file.close()

func add_score(amount: int):
	score += amount
	if score > highscore:
		highscore = score
		save_score()

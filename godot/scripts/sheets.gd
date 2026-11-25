extends RefCounted
## Crop regions for each character sheet (assets/sheets/<id>.webp, 2000x1500).
## Each sheet has its own layout, so regions are measured per character.
## face = a neutral front head shot, body = the front full-body turnaround.

const REGIONS := {
	"oli":    {"face": Rect2(990, 30, 460, 460),   "body": Rect2(60, 90, 460, 1400)},
	"leon":   {"face": Rect2(960, 40, 480, 480),   "body": Rect2(90, 30, 450, 1430)},
	"ren":    {"face": Rect2(1150, 220, 420, 420), "body": Rect2(70, 150, 340, 1220)},
	"mio":    {"face": Rect2(1020, 770, 300, 300), "body": Rect2(40, 70, 600, 1370)},
	"haru":   {"face": Rect2(790, 230, 360, 360),  "body": Rect2(60, 240, 380, 1170)},
	"setsu":  {"face": Rect2(1075, 330, 280, 280), "body": Rect2(60, 320, 290, 1230)},
	"lumi":   {"face": Rect2(1410, 90, 480, 480),  "body": Rect2(440, 90, 520, 1350)},
	"null":   {"face": Rect2(950, 130, 460, 460),  "body": Rect2(100, 90, 400, 1300)},
	"kuroba": {"face": Rect2(1300, 170, 300, 300), "body": Rect2(50, 90, 390, 1290)},
	"fumi":   {"face": Rect2(990, 60, 400, 400),   "body": Rect2(90, 90, 380, 1300)},
}

static var _cache := {}


static func has(id: String) -> bool:
	return REGIONS.has(id) and ResourceLoader.exists(_path(id))


static func _path(id: String, part := "face") -> String:
	# body crops come from the transparent cutouts (tools/make_cutouts.py)
	if part == "body" and ResourceLoader.exists("res://assets/cutouts/%s.png" % id):
		return "res://assets/cutouts/%s.png" % id
	return "res://assets/sheets/%s.webp" % id


static func crop(id: String, part: String) -> Texture2D:
	if not has(id):
		return null
	var key := id + ":" + part
	if not _cache.has(key):
		var a := AtlasTexture.new()
		a.atlas = load(_path(id, part))
		a.region = REGIONS[id][part]
		_cache[key] = a
	return _cache[key]


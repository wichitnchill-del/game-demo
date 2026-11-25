extends Node
## Persistent game state (autoload "Game"): party, level, bonds, story flags.

const BEAT := {"ดิน": "ลม", "ลม": "น้ำ", "น้ำ": "ไฟ", "ไฟ": "ดิน"}
const SEAL_NAMES := ["ปกติ", "ร้าว", "แตก"]
const LEON_BOND_NEEDED := 4
const BOND_MAX := 5

const WAVES := [
	[{"name": "ลูกน้องเอ็นจิ", "el": "ไฟ", "hp": 120, "atk": 11, "color": "c0603a"},
	 {"name": "ลูกน้องเอ็นจิ", "el": "ดิน", "hp": 110, "atk": 10, "color": "8a6a3a"},
	 {"name": "ลูกน้องเอ็นจิ", "el": "น้ำ", "hp": 100, "atk": 10, "color": "3a6aa0"}],
	[{"name": "เอ็นจิ", "el": "ไฟ", "hp": 320, "atk": 15, "color": "d0401a", "boss": true, "speed": 4.6},
	 {"name": "ลูกน้องเอ็นจิ", "el": "ลม", "hp": 130, "atk": 11, "color": "5a9a6a"},
	 {"name": "ลูกน้องเอ็นจิ", "el": "ไฟ", "hp": 130, "atk": 11, "color": "c0603a"}],
	[{"name": "เลออน (ธาตุไฟ เกรด 1)", "el": "ไฟ", "hp": 650, "atk": 19, "boss": true, "hidden": true, "leon": true, "sprite": "leon", "speed": 4.8}],
]

const BASE_PARTY := [
	{"id": "ren", "name": "เรน", "line": "เสริม", "el": "", "grade": 6, "hp": 90, "atk": 11, "skills": ["สามวินาที", "Support"], "drain": 1.4},
	{"id": "mio", "name": "มิโอ", "line": "เสริม", "el": "ดิน", "grade": 4, "hp": 150, "atk": 12, "skills": ["กำแพงดิน"], "crack_easy": true},
	{"id": "oli", "name": "โอลี่", "line": "แปร", "el": "ลม", "grade": 5, "hp": 95, "atk": 10, "skills": ["เอียงโชค"]},
	{"id": "haru", "name": "ฮารุ", "line": "แปร", "el": "น้ำ", "grade": 3, "hp": 85, "atk": 14, "skills": ["น้ำสะท้อน"]},
	{"id": "setsu", "name": "เซ็ตสึ", "line": "แปร", "el": "ลม", "grade": 3, "hp": 80, "atk": 13, "skills": ["ศรลม"], "drain": 1.5},
]

## Who Oli can spend school time with, and lines per bond level.
const HANGOUTS := {
	"ren": {"name": "เรน", "place": "ดาดฟ้า", "lines": [
		"เรนนั่งนิ่ง ไม่พูดอะไร แต่ก็ไม่ไล่", "“สามวินาทีของฉัน… มันสั้นลงทุกที”",
		"เรนยื่นขนมปังครึ่งก้อนมาให้", "“ถ้าวันหนึ่งฉันลืมนาย… ช่วยเตือนด้วย”", "เรนหัวเราะออกมาเป็นครั้งแรก"]},
	"mio": {"name": "มิโอ", "place": "สนามซ้อม", "lines": [
		"มิโอยกกระสอบทรายให้ดูทีละสองลูก", "“รับแทนได้ ไม่ใช่ว่าไม่เจ็บนะ”",
		"มิโอสอนท่าตั้งรับ", "“ตราฉันร้าวง่าย แต่ฉันไม่ถอย”", "มิโอตบหลังโอลี่จนไอ"]},
	"haru": {"name": "ฮารุ", "place": "ห้องสมุด", "lines": [
		"ฮารุพยักหน้าเบาๆ แล้วอ่านหนังสือต่อ", "หยดน้ำลอยรอบตัวเธอแวบหนึ่ง",
		"“ยิ้มแบบนั้น… ไม่เหนื่อยเหรอ”", "ปลายแขนเสื้อเธอชื้นขึ้นอีกนิด เธอไม่ได้ถอยออกไป", "“พรุ่งนี้… มาอีกไหม”"]},
	"setsu": {"name": "เซ็ตสึ", "place": "ลานยิงธนู", "lines": [
		"เซ็ตสึยิงเข้ากลางเป้าโดยไม่หันมามอง", "“หายใจออกก่อนปล่อยลม”",
		"เซ็ตสึให้ยืมถุงมือ", "“นายเล็งดีกว่าที่คิด”", "เซ็ตสึยอมเล่าเรื่องพี่สาว"]},
	"leon": {"name": "เลออน", "place": "หลังโรงยิม", "lines": [
		"เลออนจ้องกลับ ไฟวูบที่ปลายนิ้ว", "“มาทำไม ลูกคนกลางบ้านคาเนล”",
		"เลออนไม่ได้ไล่ แค่หันหลังให้", "“นายก็ไม่มีใครมองเหมือนกันสินะ”", "เลออนโยนกระป๋องน้ำมาให้"]},
}

var party: Array = []
var bonds := {"ren": 0, "mio": 0, "haru": 0, "setsu": 0, "leon": 0}
var lv := 1
var exp := 0
var wave := 0
var clover := 0


func new_game() -> void:
	lv = 1
	exp = 0
	wave = 0
	clover = 0
	for k in bonds:
		bonds[k] = 0
	party = []
	for base in BASE_PARTY:
		var c: Dictionary = base.duplicate(true)
		c["maxhp"] = c["hp"] + lv * 8
		c["hp"] = c["maxhp"]
		c["atk"] = c["atk"] + lv * 2
		c["breath"] = 100
		c["seal"] = 0
		party.append(c)


func mult(a: String, d: String) -> float:
	if a == "" or d == "":
		return 1.0
	if BEAT.get(a, "") == d:
		return 1.5
	if BEAT.get(d, "") == a:
		return 0.7
	return 1.0


## Bond bonus: +4% attack per bond point with Oli (Oli himself uses the average).
func bond_atk_mult(id: String) -> float:
	if id == "oli":
		var s := 0
		for k in ["ren", "mio", "haru", "setsu"]:
			s += bonds[k]
		return 1.0 + 0.04 * s / 4.0
	return 1.0 + 0.04 * bonds.get(id, 0)


func add_exp(g: int) -> Array:
	var msgs := []
	exp += g
	while exp >= lv * 80:
		exp -= lv * 80
		lv += 1
		msgs.append("★ เลเวลขึ้น! Lv %d" % lv)
		for p in party:
			p["maxhp"] += 8
			p["atk"] += 2
	return msgs


## Between waves: heal HP, restore breath; cracked seals stay.
func rest_party(breath: int) -> void:
	for p in party:
		p["breath"] = min(100, p["breath"] + breath)
		if p["seal"] < 2:
			p["hp"] = max(p["hp"], int(p["maxhp"] * 0.6))

"""Pull every spoken line out of godot/scripts/story.gd into lines.json.
Key = md5(who + "|" + text)[:12]; cutscene.gd computes the same key to find the file."""
import re, json, hashlib, pathlib
src = (pathlib.Path(__file__).parent / "../../godot/scripts/story.gd").read_text(encoding="utf-8")
lines, seen = [], set()
for who, text in re.findall(r'\[\s*"([^"@]*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\]', src):
    key = hashlib.md5(f"{who}|{text}".encode("utf-8")).hexdigest()[:12]
    if key in seen:
        continue
    seen.add(key)
    spoken = re.sub(r"^\([^)]*\)\s*", "", text).strip()          # drop leading stage direction
    if not spoken or (text.startswith("(") and text.endswith(")") and spoken == ""):
        continue
    if re.fullmatch(r"\(.*\)", text.strip()):                     # whole line is a stage direction
        continue
    lines.append({"key": key, "who": who, "text": text, "speak": spoken})
out = pathlib.Path(__file__).parent / "lines.json"
out.write_text(json.dumps(lines, ensure_ascii=False, indent=1), encoding="utf-8")
print(len(lines), "lines,", sum(len(l["speak"]) for l in lines), "characters")

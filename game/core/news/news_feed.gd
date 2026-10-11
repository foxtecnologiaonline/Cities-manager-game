class_name NewsFeed
extends RefCounted
## Bounded log of notable events (disasters, milestones) for the HUD's
## "newspaper" panel. Oldest entries drop off once MAX_ENTRIES is hit.

const MAX_ENTRIES := 20

var entries: Array[Dictionary] = [] ## [{month:int, text:String}, ...] oldest first

func add(month: int, text: String) -> void:
	entries.append({"month": month, "text": text})
	if entries.size() > MAX_ENTRIES:
		entries.pop_front()

## Most recent `count` entries, oldest first.
func latest(count: int = 5) -> Array[Dictionary]:
	var start: int = max(0, entries.size() - count)
	return entries.slice(start)

func to_dict() -> Dictionary:
	return {"entries": entries}

func from_dict(data: Dictionary) -> void:
	entries.clear()
	var raw: Array = data.get("entries", [])
	for item in raw:
		entries.append({
			"month": int(item.get("month", 0)),
			"text": str(item.get("text", "")),
		})

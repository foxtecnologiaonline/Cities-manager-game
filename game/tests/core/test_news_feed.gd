extends GutTest

func test_add_and_latest() -> void:
	var news := NewsFeed.new()
	news.add(1, "Primeiro evento.")
	news.add(2, "Segundo evento.")
	var latest := news.latest(1)
	assert_eq(latest.size(), 1)
	assert_eq(latest[0]["text"], "Segundo evento.")

func test_caps_at_max_entries() -> void:
	var news := NewsFeed.new()
	for i in range(NewsFeed.MAX_ENTRIES + 5):
		news.add(i, "Evento %d" % i)
	assert_eq(news.entries.size(), NewsFeed.MAX_ENTRIES)
	assert_eq(news.entries[0]["month"], 5) # the oldest 5 entries were dropped

func test_save_and_load_round_trip() -> void:
	var news := NewsFeed.new()
	news.add(3, "Evento salvo.")
	var loaded := NewsFeed.new()
	loaded.from_dict(news.to_dict())
	assert_eq(loaded.entries.size(), 1)
	assert_eq(loaded.entries[0]["text"], "Evento salvo.")

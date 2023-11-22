CREATE (:Page {url_hash: "aHR0cHM6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kvYWRvbGZfaGl0bGVy"})
CREATE INDEX page_hash_url_index FOR (p:Page) ON (p.hash_url)
CREATE CONSTRAINT page_hash_url_constraint for (p:Page) REQUIRE p.url_hash IS UNIQUE


CREATE (:Page {url_hash: "aHR0cHM6Ly9lbi53aWtpcGVkaWEub3JnL3dpa2kvQWRvbGZfSGl0bGVy"})
CREATE INDEX ON :Page(url_hash);
CREATE CONSTRAINT ON (p:Page) ASSERT p.url_hash IS UNIQUE;
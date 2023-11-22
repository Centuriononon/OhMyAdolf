start:
	- docker-compose up --build
stop:
	- docker-compose down
neo4j:
	- docker-compose up -d neo4j
unit-tests:
	- docker-compose -f docker-compose.test.yml down && \
	docker-compose -f docker-compose.test.yml up
neo4j/test:
	- docker-compose -f docker-compose.test.yml up -d neo4j
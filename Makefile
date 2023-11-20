build:
	- docker-compose build
down:
	- docker-compose down
neo4j:
	- docker-compose up neo4j
unit-tests:
	- docker-compose -f docker-compose.test.yml up
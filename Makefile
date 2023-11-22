up:
	- docker-compose up --build
down:
	- docker-compose down
neo4j:
	- docker-compose up -d neo4j
up/test:
	- docker-compose -f docker-compose.test.yml up --build
server/test:
	- docker-compose -f docker-compose.test.yml up --build server
neo4j/test:
	- docker-compose -f docker-compose.test.yml up -d neo4j
down/test:
	- docker-compose -f docker-compose.test.yml down
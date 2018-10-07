help:
	@echo "help                This help message"

dev-up:
	docker-compose up

dev-build:
	docker-compose build

dev-shell:
	docker-compose run web bash

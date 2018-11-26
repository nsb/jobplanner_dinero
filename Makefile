help:
	@echo "help                This help message"
	@echo "dev-up              Start compose"
	@echo "dev-build           Build compose images"
	@echo "dev-shell           Start a bash shell for the web container"

dev-up:
	docker-compose up

dev-build:
	docker-compose build

dev-shell:
	docker-compose run web bash

test:
	docker-compose run web mix test

.PHONY: test
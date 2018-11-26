.PHONY: help

APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VSN ?= `grep 'version:' mix.exs | cut -d '"' -f2`
APP_DIR ?= `pwd`
HOST ?= dev
MIGRATE ?= false
SEED ?= false

help:
	@echo "$(APP_NAME):$(APP_VSN)"
	@perl -nle 'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build:
	@echo "building base image"
	docker build -t elixir-ubuntu:latest .
	@echo "building release"
	sudo rm -r _build/ deps/ assets/node_modules/ .mix/ .hex/
	docker run -v $(APP_DIR):/opt/build --rm -it elixir-ubuntu:latest /opt/build/bin/build
	@echo "cleaning up"
	sudo rm -r _build/ deps/ assets/node_modules/ .mix/ .hex/
	mix deps.get

deploy: build
	@echo "deploying $(APP_NAME):$(APP_VSN) to ${HOST}"
	@if [ "${SEED}" = "true" ]; then \
		./bin/deploy --host ${HOST} --seed; \
	elif [ "${MIGRATE}" = "true" ]; then \
		./bin/deploy --host ${HOST} --migrate; \
	else \
		./bin/deploy --host ${HOST}; \
	fi

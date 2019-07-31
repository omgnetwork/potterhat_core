all: clean build

ENV_TEST        ?= env MIX_ENV=test

LANG            := en_US.UTF-8
LC_ALL          := en_US.UTF-8

#
# Setting-up
#

deps:
	mix deps.get

.PHONY: deps

#
# Cleaning
#

clean:
	rm -rf _build/
	rm -rf deps/

.PHONY: clean

#
# Linting
#

format:
	mix format

check-format:
	mix format --check-formatted 2>&1

check-credo:
	$(ENV_TEST) mix credo 2>&1

check-dialyzer:
	$(ENV_TEST) mix dialyzer --halt-exit-status >&1

.PHONY: format check-format check-credo check-dialyzer

#
# Building
#

build: deps
	$(ENV_TEST) mix compile

.PHONY: build

#
# Testing
#

test: build
	$(ENV_TEST) mix test

.PHONY: test

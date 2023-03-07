ARGS = $(filter-out $@,$(MAKECMDGOALS))
MAKEFLAGS += --silent

list:
	sh -c "echo; $(MAKE) -p no_targets__ | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' | grep -v 'Makefile'| sort"

#############################
# Docker machine states
#############################

up:
	start

startdb:
	docker-compose up -d mariadb

start:
	docker-compose up -d mariadb app

recreate:
	docker-compose -f docker-compose.local.yml up -d --force-recreate mariadb app

stop:
	docker-compose stop mariadb app

state:
	docker-compose ps

rebuild:
	docker-compose stop app
	docker-compose pull app
	docker-compose rm --force app
	docker-compose build --no-cache --pull app
	docker-compose up -d --force-recreate app

#############################
# General
#############################

bash: shell

shell:
	docker-compose exec --user application app /bin/bash

root:
	docker-compose exec --user root app /bin/bash

sehn:	docker manage
#############################
# Argument fix workaround
#############################
%:
	@:

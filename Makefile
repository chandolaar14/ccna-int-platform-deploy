SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SHELLFLAGS = -uec
.PHONY: default build \
                build.tar.gz \
                plan-qa \
                clean

SUB_MAKE = make -C
JQ_COMBINE = jq -s '.[0] * .[1]'
RELEASE_BUCKET ?= release.ccna-int.deployment.ccna-int.ccna.info/platform

default:
	echo "no default target"

build: build.tar.gz

build.tar.gz:
	aws s3 cp s3://${RELEASE_BUCKET}/$$(cat platform-version)/build.tar.gz build.tar.gz

qa-plan:
	tar -xvf build.tar.gz
	${JQ_COMBINE} settings.json config/qa.json > build/settings.json
	${SUB_MAKE} build plan

uat-plan:
	tar -xvf build.tar.gz
	${JQ_COMBINE} settings.json config/uat.json > build/settings.json
	${SUB_MAKE} build plan

prod-plan:
	tar -xvf build.tar.gz
	${JQ_COMBINE} settings.json config/prod.json > build/settings.json
	${SUB_MAKE} build plan

qa-deploy:
	tar -xvf build.tar.gz
	${JQ_COMBINE} settings.json config/qa.json > build/settings.json
	${SUB_MAKE} build deploy

uat-deploy:
	tar -xvf build.tar.gz
	${JQ_COMBINE} settings.json config/uat.json > build/settings.json
	${SUB_MAKE} build deploy

prod-deploy:
	tar -xvf build.tar.gz
	${JQ_COMBINE} settings.json config/prod.json > build/settings.json
	${SUB_MAKE} build deploy

verify:
	make build
	make qa-plan
	make uat-plan

format:
	# format json
	find . -type f | egrep '.*\.json$$' | xargs npx prettier --write

clean:
	git clean -fdX

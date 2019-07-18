SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SHELLFLAGS = -uec
.PHONY: default build \
		storage.tar.gz core.tar.gz api.tar.gz \
		qa-plan uat-plan prod-plan \
		qa-deploy uat-deploy prod-deploy \
        clean

SUB_MAKE = make -C
JQ_COMBINE = jq -s '.[0] * .[1]'
UNTAR = tar -xvf
RELEASE_BUCKET ?= release.ccna-int.deployment.ccna-int.ccna.info/platform
CP = cp

default:
	echo "no default target"

define get-platform-version
    version=$$(jq -r ".$1.version" platform-version.json)
	aws s3 cp s3://${RELEASE_BUCKET}/$$version/build.tar.gz $1.tar.gz
endef

define unzip
	mkdir -p $1 && ${UNTAR} $1.tar.gz -C $1 --strip-components=1
endef

define create-settings
	${JQ_COMBINE} project-settings.json config/$1.json > settings.json
	${CP} settings.json storage/settings.json
	${CP} settings.json core/settings.json
	${CP} settings.json api/settings.json
endef

define exec
	${SUB_MAKE} storage $1
	${SUB_MAKE} core $1
	${SUB_MAKE} api $1
endef

define go
	$(call unzip,storage)
	$(call unzip,core)
	$(call unzip,api)
	$(call create-settings,$1)
	$(call exec,$2)
endef

build: storage.tar.gz core.tar.gz api.tar.gz

storage.tar.gz: platform-version.json
	$(call get-platform-version,storage)

core.tar.gz: platform-version.json
	$(call get-platform-version,core)

api.tar.gz: platform-version.json
	$(call get-platform-version,api)

qa-plan:
	$(call go,qa,plan)

uat-plan:
	$(call go,uat,plan)

prod-plan:
	$(call go,prod,plan)

qa-deploy:
	$(call go,qa,deploy)

uat-deploy:
	$(call go,uat,deploy)

prod-deploy:
	$(call go,prod,deploy)

verify: build
	$(call go,qa,plan)
	$(call go,uat,plan)

format:
	# format json
	find . -type f | egrep '.*\.json$$' | xargs npx prettier --write

clean:


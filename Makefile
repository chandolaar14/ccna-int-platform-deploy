SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SHELLFLAGS = -uec
.PHONY: default build \
		storage.tar.gz core.tar.gz api.tar.gz \
		qa-plan uat-plan irm-plan prod-plan \
		qa-deploy uat-deploy irm-deploy prod-deploy \
        clean

PROJECT_NAME = ccna-int-platform-deploy

SUB_MAKE = make -C
JQ_COMBINE = jq -s '.[0] * .[1]'
UNTAR = tar -xvf
RELEASE_BUCKET ?= release.ccna-int.deployment.ccna-int.ccna.info/platform
CP = cp

default:
	echo "no default target"

define get-platform-version
	version=$$(jq -r ".$1.version" platform-version.json)
	echo "version=[$$version] setting=[layer=$1]"
	aws s3 cp s3://${RELEASE_BUCKET}/$$version/build.tar.gz $1.tar.gz
endef

define unzip
	mkdir -p $1 && ${UNTAR} $1.tar.gz -C $1 --strip-components=1
endef

define create-setting
	jq -s ".[0] * .[1] * .[2] + {\"featureFlags\":([] + .[0].featureFlags + .[1].featureFlags + .[3].$2.features)}" project-settings.json config/$1.json config/$1-$2.json platform-version.json > $2/settings.json
endef

define create-settings
	$(call create-setting,$1,storage)
	$(call create-setting,$1,core)
	$(call create-setting,$1,api)
endef

define exec
	${SUB_MAKE} storage $1-storage
	${SUB_MAKE} core $1-core
	${SUB_MAKE} api $1-api
endef

define go
	$(call unzip,storage)
	$(call unzip,core)
	$(call unzip,api)
	$(call create-settings,$1)
	$(call exec,$2)
endef

define deploy-storage
	$(call unzip,storage)
	$(call create-setting,$1,storage)
	${SUB_MAKE} storage deploy-storage
endef

define deploy-region
	$(call unzip,core)
	$(call unzip,api)
	$(call create-setting,$1,core)
	$(call create-setting,$1,api)
	${SUB_MAKE} core deploy-core-$2
	${SUB_MAKE} api deploy-api-$2
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

irm-plan:
	$(call go,irm,plan)

prod-plan:
	$(call go,prod,plan)

qa-deploy:
	$(call go,qa,deploy)

qa-deploy-storage:
	$(call deploy-storage,qa)

qa-deploy-secondary:
	$(call deploy-region,qa,secondary)

qa-deploy-primary:
	$(call deploy-region,qa,primary)

uat-deploy-storage:
	$(call deploy-storage,uat)

uat-deploy-secondary:
	$(call deploy-region,uat,secondary)

uat-deploy-primary:
	$(call deploy-region,uat,primary)

prod-deploy-storage:
	$(call deploy-storage,prod)

prod-deploy-secondary:
	$(call deploy-region,prod,secondary)

prod-deploy-primary:
	$(call deploy-region,prod,primary)


uat-deploy:
	$(call go,uat,deploy)

irm-deploy:
	$(call go,irm,deploy)

prod-deploy:
	$(call go,prod,deploy)

verify: build
	$(call go,qa,plan)
	$(call go,uat,plan)
	$(call go,irm,plan)

format:
	# format json
	find . -type f | egrep '.*\.json$$' | xargs npx prettier --write

open-pipeline:
	open "https://us-west-2.console.aws.amazon.com/codesuite/codepipeline/pipelines/$(PROJECT_NAME)/view?region=us-west-2"

clean:
	git clean -fdX

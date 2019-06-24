SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SHELLFLAGS = -uec
.PHONY: default build \
                build.tar.gz \
                plan-qa \
                clean

COPY = cp
RM = rm -rf
S3CP = aws s3 cp
SUB_MAKE = make -C 
JQ_COMBINE = jq -s '.[0] * .[1]'
RELEASE_BUCKET ?= release.ccna-int.deployment.ccna-int.ccna.info


default:
	echo "no default target"

build: build.tar.gz

build.tar.gz:
	aws s3 cp s3://${RELEASE_BUCKET}/$$(cat platform-version) build.tar.gz

qa-plan:
	tar -xvf build.tar.gz
	${JQ_COMBINE} settings.json config/qa.json > build/settings.json
#	cp jsonnet_MacOS build/jsonnet/jsonnet
	${SUB_MAKE} build plan-platform

uat-plan:
	tar -xvf build.tar.gz
	${JQ_COMBINE} settings.json config/uat.json > build/settings.json
#	cp jsonnet_MacOS build/jsonnet/jsonnet
	${SUB_MAKE} build plan-platform

qa-deploy:
	tar -xvf build.tar.gz
	${JQ_COMBINE} settings.json config/qa.json > build/settings.json
#	cp jsonnet_MacOS build/jsonnet/jsonnet
	${SUB_MAKE} build deploy-platform

uat-deploy:
	tar -xvf build.tar.gz
	${JQ_COMBINE} settings.json config/uat.json > build/settings.json
#	cp jsonnet_MacOS build/jsonnet/jsonnet
	${SUB_MAKE} build deploy-platform

clean:
	# remove each file or folder mentioned in the gitignore
	${RM} $$(cat ./.gitignore)
	for folder in ${CLEAN_DIRS}; do ${SUB_MAKE} $$folder clean; done

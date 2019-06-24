SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SHELLFLAGS = -uec
.PHONY: default build clean \
		get-platform-package \
		execute-integration-tests

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

clean:
	# remove each file or folder mentioned in the gitignore
	${RM} $$(cat ./.gitignore)
	for folder in ${CLEAN_DIRS}; do ${SUB_MAKE} $$folder clean; done

execute-integration-tests: 
	${SUB_MAKE} integration-tests execute

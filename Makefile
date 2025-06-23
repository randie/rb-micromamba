include .env  # defines USERNAME, USER_ID, GROUP_ID
export

.ONESHELL:
.SHELL := /bin/bash

IMAGE_NAME := rb-micromamba
IMAGE_TAG  := $(or $(TAG),latest)

.PHONY: default
default: base-img

#   ┌───────────────────────────┐
#   │  E N V   L O C K F I L E  │
#   └───────────────────────────┘

MICROMAMBA_IMAGE  := mambaorg/micromamba:2.1.1
CLEANUP_LOCKFILE  := ./bin/cleanup_lockfile.py
ENV_NAME          := rb-micromamba-env

env_lock.yml: env.yml
	@echo "📦 Generating $@ from $<"
	@if [ -f $@ ]; then
		mv -f $@ env_lock_$$(date +%y%m%d%H%M).yml
	fi
	docker run --rm \
		--volume "$(CURDIR):/work" \
		--workdir /work \
		$(MICROMAMBA_IMAGE) \
		/bin/bash -c "\
			micromamba create -n $(ENV_NAME) -y -f $< && \
			micromamba env export -n $(ENV_NAME) > /work/$@"
	$(CLEANUP_LOCKFILE) $@
	@echo "✅ $@ complete"

#   ┌───────────────────────┐
#   │  B A S E   L A Y E R  │
#   └───────────────────────┘

.PHONY: base-img base-keep-alive base-sh

base-img: env_lock.yml
	docker build \
	  --build-arg USERNAME=$(USERNAME) \
	  --build-arg USER_ID=$(USER_ID) \
	  --build-arg GROUP_ID=$(GROUP_ID) \
	  -t $(IMAGE_NAME):$(IMAGE_TAG) .

base-keep-alive:
	docker run -d \
		--rm \
		--name rb-micromamba-ka \
		--volume "$(CURDIR):/work" \
		--workdir /work \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		tail -f /dev/null

base-sh:
	if ! docker images --format '{{.Repository}}' | grep -q '^rb-micromamba$$'; then
		$(MAKE) base-img
	fi
	if ! docker ps --format '{{.Names}}' | grep -q '^rb-micromamba-ka$$'; then
		$(MAKE) base-keep-alive
	fi
	docker exec -it rb-micromamba-ka /bin/bash


#   ┌───────────────────────────┐
#   │  G H C R   P U B L I S H  │
#   └───────────────────────────┘

GHCR_REGISTRY := ghcr.io
GHCR_IMAGE     = $(GHCR_REGISTRY)/$${GHCR_USER}/$(IMAGE_NAME):$(IMAGE_TAG)
GHCR_VERSIONS  = /users/$$GHCR_USER/packages/container/$(IMAGE_NAME)/versions

.PHONY: ghcr-login ghcr-tag ghcr-push ghcr-status ghcr-publish ghcr-list-versions ghcr-delete-version ghcr-delete-untagged 

# -- Macros --

define assert-ghcr-user
@if [ -z "$$GHCR_USER" ]; then
  echo "❌ GHCR_USER is not set."
  echo "   Set it in your .envrc and ensure direnv is active."
  exit 1
fi
endef

define assert-ghcr-pat
@if [ -z "$$GHCR_PAT" ]; then
  echo "❌ GHCR_PAT is not set."
  echo "   Set it in your .envrc and ensure direnv is active."
  exit 1
fi
endef

# -- Targets --

ghcr-login:
	$(assert-ghcr-user)
	$(assert-ghcr-pat)
	echo "$$GHCR_PAT" | docker login $(GHCR_REGISTRY) -u "$$GHCR_USER" --password-stdin

ghcr-tag:
	$(assert-ghcr-user)
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(GHCR_IMAGE)

ghcr-push: ghcr-login ghcr-tag
	docker push $(GHCR_IMAGE) && \
	echo "✅ Image available at: https://ghcr.io/v2/$$GHCR_USER/$(IMAGE_NAME)/manifests/$(IMAGE_TAG)"

ghcr-status:
	$(assert-ghcr-user)
	@echo "✅ Image available at: https://ghcr.io/v2/$$GHCR_USER/$(IMAGE_NAME)/manifests/$(IMAGE_TAG)\n"
	@echo "Version IDs	Tags"
	@echo "-----------	----"
	gh api $(GHCR_VERSIONS) --header "Accept: application/vnd.github+json" | \
	  jq -r '.[] | "\(.id)\t\(.metadata.container.tags | join(", "))"'

ghcr-delete-version:     # delete by version ID
	$(assert-ghcr-user)
	if [ -z "$(VERSION_ID)" ]; then
		echo "VERSION_ID is not set. Usage: make ghcr-delete-version VERSION_ID=<id> [FORCE=1]"
		exit 1
	fi
	if [ "$(FORCE)" = "1" ]; then
		gh api --method DELETE $(GHCR_VERSIONS)/$(VERSION_ID) --header "Accept: application/vnd.github+json" && \
		echo "🧾 Deleted version ID: $(VERSION_ID)"
	else
		echo "🚫 (DRY RUN) delete version ID: $(VERSION_ID)"
	fi	

ghcr-delete-untagged:    # delete untagged versions
	$(assert-ghcr-user)
	UNTAGGED_IDS=$$( gh api $(GHCR_VERSIONS) --header "Accept: application/vnd.github+json" | \
	  jq -r '.[] | select((.metadata.container.tags | length // 0) == 0) | .id')
	if [ -z "$$UNTAGGED_IDS" ]; then
		echo "✅ No untagged versions found for $(IMAGE_NAME)"
		exit 0
	fi
	if [ "$(FORCE)" = "1" ]; then
		echo "🗑️ Deleting untagged versions: \n$$UNTAGGED_IDS"
		for id in $$UNTAGGED_IDS; do
		gh api --method DELETE $(GHCR_VERSIONS)/$$id --header "Accept: application/vnd.github+json" && \
		echo "🧾 Deleted version ID: $$id"
		done
	else
		echo "🚫 (DRY RUN) delete untagged versions: \n$$UNTAGGED_IDS"
	fi

#   ┌─────────────────┐
#   │  H E L P E R S  │
#   └─────────────────┘

.PHONY: clean

clean:  # Remove containers, image, and dangling layers
	-docker ps -a --filter ancestor=rb-micromamba:latest --format '{{.ID}}' | xargs -r docker rm -f
	-docker rmi rb-micromamba:latest
	-docker image prune -f
	@echo "✅ Clean complete"

.PHONY: buildx manifest buildfat check run debug push save clean clobber

# Default values for variables
REPO  ?= mgkahn/
NAME  ?= firebird3
TAG   ?= latest
ARCH  := $$(arch=$$(uname -m); if [[ $$arch == "x86_64" ]]; then echo amd64; else echo $$arch; fi)
PORT=3050

ARCHS = amd64 arm64
IMAGES := $(ARCHS:%=$(REPO)$(NAME):$(TAG)-%)
PLATFORMS := $$(first="True"; for a in $(ARCHS); do if [[ $$first == "True" ]]; then printf "linux/%s" $$a; first="False"; else printf ",linux/%s" $$a; fi; done)


# Rebuild the container image and remove intermediary images
buildx: $(templates)
	docker buildx build --push --platform ${PLATFORMS} --tag ${REPO}/${NAME}:${TAG} .
	@danglingimages=$$(docker images --filter "dangling=true" -q); \
	if [[ $$danglingimages != "" ]]; then \
	  docker rmi $$(docker images --filter "dangling=true" -q); \
	fi

from-scratch: $(templates)
	docker buildx build --no-cache --push --platform ${PLATFORMS} --tag ${REPO}/${NAME}:${TAG} .
	@danglingimages=$$(docker images --filter "dangling=true" -q); \
	if [[ $$danglingimages != "" ]]; then \
	  docker rmi $$(docker images --filter "dangling=true" -q); \
	fi

# yarnpkg_pubkey.gpg :
# 	wget --output-document=yarnpkg_pubkey.gpg https://dl.yarnpkg.com/debian/pubkey.gpg

# Safe way to build multiarchitecture images:
# - build each image on the matching hardware, with the -$(ARCH) tag
# - push the architecture specific images to Dockerhub
# - build a manifest list referencing those images
# - push the manifest list so that the multiarchitecture image exist

run:
	docker run --detach --rm \
		--publish ${PORT}:${PORT} \
		--env ISC_PASSWORD=nurs6293 \
		--env TZ=America/Denver \
		--name ${NAME} \
	$(REPO)$(NAME):$(TAG)

debug:
	docker run --detach --rm \
		--publish ${PORT}:${PORT} \
		--env ISC_PASSWORD=nurs6293 \
		--env TZ=America/Denver \
		--name ${NAME} \
	$(REPO)$(NAME):$(TAG)

	# Log into the container
	echo "Logging into ${NAME} Firebird container"
	docker exec -it ${NAME} /bin/bash

	
push:
	docker push $(REPO)$(NAME):$(TAG)

save:
	docker save $(REPO)$(NAME):$(TAG) | gzip > $(NAME)-$(TAG).tar.gz

clean:
	docker image prune -f

clobber:
	docker rmi $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)
	docker builder prune --all

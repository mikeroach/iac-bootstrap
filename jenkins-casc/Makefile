username = mikeroach
image = jenkins-lts-alpine-casc
tag := $(shell date +%Y%m%d-%H%M)

.PHONY = image push

image:
	docker build . -t $(username)/$(image):$(tag)

push:
	docker push $(username)/$(image):$(tag)

all: clean dbuild kube
compose: clean dbuild up
kube: kclean kapply

gitdir ?= react-image-compressor
os ?= $(shell uname -s | tr 'A-Z' 'a-z')

clone:
	@-rm -rf ${gitdir}
	@git clone https://github.com/RaulB-masai/react-image-compressor.git ${gitdir}

dbuild: clone
	@docker-compose build

up:
	docker-compose up -d

down:
	-docker-compose down

clean: down kclean
	@-rm -rf ${gitdir}
	@-docker rmi nginx-proxy nodejs-react
	@echo Docker environment cleaned up

view-logs:
	@docker-compose logs nginx

init-bin:
	@mkdir -p bin
	@[ ! -x bin/kompose ] && curl -L -o bin/kompose https://github.com/kubernetes/kompose/releases/download/v1.21.0/kompose-${os}-amd64 && chmod +x bin/kompose || true
	@[ ! -x bin/kubectl ] && curl -L -o bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/$(shell curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/${os}/amd64/kubectl" && chmod +x bin/kubectl || true
	@echo Binaries ready

kconvert: init-bin kclean
	@mkdir -p kubefiles
	@./bin/kompose convert -f docker-compose.yml -o kubefiles
	@echo Kubernetes YAML files generated off the docker-compose.yml file

kapply: kconvert
	@find kubefiles -type f -name "*.yaml" | xargs -n1 ./bin/kubectl apply -f
	@echo Kubernetes YAML files applied

kclean:
	@-find kubefiles -type f -name "*.yaml" | xargs -n1 ./bin/kubectl delete -f
	@-rm -rf kubefiles
	@echo Kubernetes environment cleaned up

ktest:
	./bin/kubectl -n default port-forward deployment/nginx 8080


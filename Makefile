all: clean dbuild kube
compose: clean dbuild up
kube: kclean kapply

os ?= $(shell uname -s | tr 'A-Z' 'a-z')

NGINX_REPO_NAME ?= nginx-proxy
NODEJS_REPO_NAME ?= nodejs-react
IMAGE_TAG ?= latest
export

dprepare:
	@eval "(echo 'cat <<DELIMITER' ; cat docker-compose.yml.tpl ; echo DELIMITER )" | sh > docker-compose.yml

dbuild: dprepare
	@git submodule init
	@git submodule update
	@docker-compose build

up:
	docker-compose up -d
	@echo Local docker compose environment up. Please connect to http://localhost:8080

down:
	-docker-compose down

view-logs:
	@docker-compose logs nginx

init-bin:
	@mkdir -p bin
	@[ ! -x bin/kompose ] && curl -L -o bin/kompose https://github.com/kubernetes/kompose/releases/download/v1.21.0/kompose-${os}-amd64 && chmod +x bin/kompose || true
	@[ ! -x bin/kubectl ] && curl -L -o bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/$(shell curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/${os}/amd64/kubectl" && chmod +x bin/kubectl || true
	@echo Binaries ready

kconvert: init-bin kclean dprepare
	@mkdir -p kubefiles
	@./bin/kompose convert -f docker-compose.yml -o kubefiles
	@echo Kubernetes YAML files generated off the docker-compose.yml file

kapply: kconvert
	@find kubefiles -type f -name "*.yaml" | xargs -r -n1 ./bin/kubectl apply -f
	@echo Kubernetes YAML files applied

kclean:
	@-find kubefiles -type f -name "*.yaml" | xargs -r -n1 ./bin/kubectl delete -f
	@-rm -rf kubefiles
	@echo Kubernetes environment cleaned up

ktest:
	@echo Local kubernetes environment up. Please connect to http://localhost:8080
	@./bin/kubectl -n default port-forward deployment/nginx 8080

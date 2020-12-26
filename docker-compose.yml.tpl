version: "3"
services:
  nginx:
    image: ${NGINX_REPO_NAME}:${IMAGE_TAG}
    build:
      context: .
      dockerfile: Dockerfile.nginx
    restart: always
    ports:
      - "8080:8080"
    labels:
      kompose.image-pull-policy: IfNotPresent
      kompose.image-pull-secret: ${REGISTRY_SECRET_NAME}
    depends_on:
      - nodejs
    links:
      - nodejs
  nodejs:
    image: ${NODEJS_REPO_NAME}:${IMAGE_TAG}
    build:
      context: .
      dockerfile: Dockerfile.nodejs
    restart: always
    expose:
      - "3000"
    labels:
      kompose.image-pull-policy: IfNotPresent
      kompose.image-pull-secret: ${REGISTRY_SECRET_NAME}

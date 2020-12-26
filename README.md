# kubejs

Sample React project wrapped inside a docker-compose environment, moved to kubernetes and eventually deployed to production using AWS services.

## Scenario

A sample React web application has to be published through a Nginx reverse proxy. First of all the development environment needs to be created using Docker Compose. Then it has to be moved to a local Kubernetes platform. Finally the project will be deployed to production making use of some AWS services: ECR and CodeBuild.

## Implementation

All the steps used for deployment/testing purposes have been defined as `Makefile` targets and can therefore be executed by calling `make <target>`.

## Local Docker Compose

Two different Docker images have been baked off the proper Dockerfiles, `Dockerfile.nginx` and `Dockerfile.nodejs`, in order to keep the reverse proxy separated from the actual application. The images can be built running `make dbuild`. The `docker-compose.yml` file is generated at runtime using the environment variables to fill some placeholders in a template file. This allows to keep a single file for both local testing environment and the final production deployment.

The `docker-compose.yml` file describes the Docker Compose environment, which makes sure that the nginx container is exposed on port 8080 whilst keeping the nodejs container talk to the external world through it. Every single request is logged to the nginx container's standard output and logs can be watched by executing `make view-logs`. The whole environment can be brought up with `make up` and torn down with `make down`.

## Local Kubernetes platform

For the sake of local kubernetes testing it's possible to use Minikube (https://minikube.sigs.k8s.io/), sourcing its docker environment variables in a terminal (by executing `eval $(minikube docker-env)` or `minikube docker-env | . /dev/stdin`), in order to build and make the Docker images available to Minikube.

`make kapply` carries on a number of tasks:
* it provides `konvert` for converting the `docker-compose.yml` file to YAML deployment and service files to feed Kubernetes with;
* it provides `kubectl`, the swiss-army knife for dealing with Kubernetes;
* it converts and applies the previously mentioned YAML files.

`make ktest` forwards the nginx port to test the service from outside the Minikube platform, making it possible to browse http://localhost:8080 to take a look at the application.

## Ingegration with AWS services and deployment to production

The `aws` folder contains some Terraform code that can build the infrastructure on AWS required to build and deploy the application to an existing Kubernetes cluster. Creating and operating such cluster is beyond the scope of this project.

Such infrastructure lives within an AWS account and is composed of:
* two ECR repositories, one per Docker image used in this project;
* a CodeBuild project;
* an IAM role the CodeBuild service can assume in order to accomplish the tasks it's been designed for.

The `variables.tf` file declares the variables that are going to be used within the Terraform code, namely:
* **region**: the AWS region we want to run our services into;
* **k8s_cluster**: hostname and port of the Kubernetes cluster the application has to be deployed to;
* **k8s_username**: the username to authenticate to the Kubernetes cluster as;
* **k8s_password_parameter**: the name of the SecureString parameter in AWS SSM Parameter Store to retrieve the password for the above username from. The creation of this parameter is not part of this code in order not to leak sensitive information in the state file or in the code itself.

The `main.tf` file hosts the actual Terraform code for creating all the resources, whilst `output.tf` declares the outputs of this Terraform stack: the repository URLs for both the Docker images and the CodeBuild project badge, to display it into this README.md to show the status of the builds.

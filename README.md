# Infrastructure as Code Bootstrap (Terraform)

***"Give me a place to stand, and I shall move the earth." -Archimedes***

This repository contains Terraform to instantiate and manage these resources supporting the [Aphorismophilia project:](https://github.com/mikeroach/aphorismophilia)

* Google Cloud Platform master [seed project](https://github.com/terraform-google-modules/terraform-google-project-factory/blob/v3.2.0/docs/GLOSSARY.md) aka [Terraform admin project](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform)
    * Used by the [GCP Project Factory Terraform Module](https://github.com/terraform-google-modules/terraform-google-project-factory) to create other GCP projects
* GCS bucket for Terraform remote states
* GCP management environment project
* Shared VPC and related network elements (including firewall rules)
* GCP instance as Docker container host with persistent storage
	* configured via the Salt Masterless provisioner using the companion [Salt state + pillar combined repository](https://github.com/mikeroach/iac-bootstrap-salt)
* Jenkins Docker container with [Configuration-as-Code support](https://jenkins.io/projects/jcasc/)
    * image built from [jenkins-casc/Dockerfile](jenkins-casc/Dockerfile)
    * configured from [jenkins-casc/jenkins.yaml](jenkins-casc/jenkins.yaml)
    * credentials encrypted with [git-crypt](https://www.agwa.name/projects/git-crypt/) and injected via Docker runtime environment variables
    * Terraform, Google Cloud SDK, and other tools included
* GCP projects for application delivery environments (resources therein managed by [stack template-driven pipelines](https://github.com/mikeroach/iac-template-pipeline))

Once bootstrapped, this infrastructure gives us a place to run the rest of our automated IaC and CI/CD pipelines. I manage these build/management resources out-of-band (i.e. from a laptop) on an ongoing basis in the so-called [Singleton Stack Antipattern](https://infrastructure-as-code.com/patterns/stack-replication/singleton-stack.html). While this could be adapted to run via a templated IaC pipeline instead (outside initialization and disaster recovery scenarios), I found the drawbacks of this antipattern worth it to avoid the complexity of multiple bootstrap environments as well as the chicken/egg problems that would occur when Terraforming resources from inside those same resources. I also appreciated a simpler introduction to Terraform before moving on to pipeline-driven automation use cases.

### Prerequisites
* Latest version of the [iac-bootstrap-salt](https://github.com/mikeroach/iac-bootstrap-salt) repository cloned locally
* Google Cloud Platform organization and admin credentials
* Docker Hub account with configured repository
* Terraform (tested with 12.x)
* Gcloud SDK 249.0.0+
* GNU Make
* jq

### Usage

⚠️ These instructions are intended for my own reference in managing my [personal project's](https://github.com/mikeroach/aphorismophilia) environments, not an endorsement of suitability for anyone else's general use.

Some module outputs are inputs to other modules (e.g. the Docker provider needs to know the ephemeral address of our Docker GCP instance), however due to Terraform issues [#17101](https://github.com/hashicorp/terraform/issues/17101) and [#2430](https://github.com/hashicorp/terraform/issues/2430) the nested module actions need to be invoked imperatively. The `bootstrap` make target runs the steps necessary to stand up this bootstrap environment in the correct order.

#### First Run

1. Reference [iac-bootstrap-terraform/variables.tf](iac-bootstrap-terraform/variables.tf) and configure variables in `secrets/secret.tfvars` accordingly.
1. Update `jenkins-casc/jenkins.yaml` with desired Jenkins configuration.
1. In `iac-bootstrap-terraform`, run `make bootstrap` and follow the prompts. This is an interactive process since we can't enable Terraform remote state until the GCS bucket is created, or easily manage a custom ACL without knowing the dynamically generated Seed Service Account ID.

#### Subsequent Runs

1. Change Terraform HCL/variables as desired.
1. In `iac-bootstrap-terraform`, run `make test plan` and inspect output.
1. In `iac-bootstrap-terraform`, run `make apply`.

#### Updating Jenkins Configuration

1. Update `jenkins-casc/jenkins.yaml` with desired changes and push to this repository.
1. (Optional) Add any sensitive data expanded through environment variables to `secrets/secret.tfvars`, then in `iac-bootstrap-terraform` run `make test plan apply` to restart the Jenkins container with new env vars injected. This also reloads the configuration from [jenkins-casc/jenkins.yaml](jenkins-casc/jenkins.yaml).
1. See [instructions](https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/docs/features/configurationReload.md) to reload CasC without restarting Jenkins.

#### Upgrading Jenkins Image/Plugins

1. Update `jenkins-casc/Dockerfile` or `plugins.txt` with desired changes.
1. In `jenkins-casc`, run `make image push` to build the new Docker image and push it to the container registry.
1. Update `docker_jenkins_image` Terraform variable in `secrets/secret.tfvars` with new image tag.
1. In `iac-bootstrap-terraform`, run `make test plan apply` to replace the running container with the new image.
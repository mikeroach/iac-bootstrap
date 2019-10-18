#terraform-cmd = docker run -it -e "TF_IN_AUTOMATION=1" -w /data --rm -v ${CURDIR}:/data hashicorp/terraform:0.12.6
terraform-cmd = terraform

TFVARS ?= "../secrets/secret.tfvars"
BACKEND ?= -backend-config=../secrets/backend.tfvars
GCP_SEED_SA_EMAIL := ${shell awk -F = '/^gcp_seed_sa_email/{gsub(/[ |\"]/, ""); print $$2}' $(TFVARS) }

VARS = -var-file=$(TFVARS)

test: tf-init tf-fmt tf-validate

plan: tf-plan

apply: tf-apply

tf-init:
	$(terraform-cmd) init -input=false $(VARS) $(BACKEND)

tf-fmt:
	$(terraform-cmd) fmt -check -recursive -diff
	$(terraform-cmd) fmt -check -recursive -diff ../secrets

#tf-lint: This doesn't recurse.
#	docker run --rm -v ${CURDIR}:/data -t wata727/tflint

tf-validate:
	$(terraform-cmd) validate $(VARS)

tf-plan:
	$(terraform-cmd) plan -input=false $(VARS)

tf-apply:
	$(terraform-cmd) apply -auto-approve $(VARS)

tf-generate-plan:
	$(terraform-cmd) plan -input=false -out=tf.plan $(VARS)

tf-apply-plan:
	$(terraform-cmd) apply -input=false tf.plan $(VARS)

bootstrap:
	$(terraform-cmd) init $(VARS)
	$(terraform-cmd) fmt -check -recursive -diff
	$(terraform-cmd) fmt -check -recursive -diff ../secrets
	$(terraform-cmd) apply $(VARS) -target=module.gcp-seed-project
	@echo "\nSeed service account ACL entry: \"OWNER:user-`cat ${GCP_SEED_SA_EMAIL}`\",\n"
	@read -e -p "Add the above to your seed_project_tfstate_acl variable, then press ENTER to continue or CTRL-C to stop. $ "
	@read -e -p "Great! Now uncomment the 'terraform { backend \"gcs\" {} }' stanza in main.tf, then press ENTER to continue or CTRL-C to stop. $ "
	$(terraform-cmd) init $(VARS) $(BACKEND)
	$(terraform-cmd) apply $(VARS) -target=module.management-project
	$(terraform-cmd) apply $(VARS) -target=module.management-project-metadata
	$(terraform-cmd) apply $(VARS) -target=module.shared-vpc
	$(terraform-cmd) apply $(VARS) -target=module.management-firewall
	$(terraform-cmd) apply $(VARS) -target=module.admin1
	$(terraform-cmd) apply $(VARS)
	@echo "All done! Remember to backup and remove the local terraform.tfstate files now that our remote backend is successfully initialized."
ifneq (, $(wildcard ./.env))
	include .env
	export
endif

define to_lower
$(shell echo $(1) | tr '[:upper:]' '[:lower:]')
endef

LOWER_TERRAFORM_ENV := $(call to_lower,$(TERRAFORM_ENV))
TERRAFORM = terraform -chdir=$(TERRAFORM_DIR) 

ifeq ($(LOWER_TERRAFORM_ENV),prod)
  TERRAFORM_DIR := ./terraform/env/prod
else
  ifeq ($(LOWER_TERRAFORM_ENV),dev)
    TERRAFORM_DIR := ./terraform/env/dev
  else
    ifeq ($(LOWER_TERRAFORM_ENV),homolog)
      TERRAFORM_DIR := ./terraform/env/homolog
    else
      $(error Unknown TERRAFORM_ENV $(LOWER_TERRAFORM_ENV). Use dev, prod, or homolog.)
    endif
  endif
endif

PLAN_FILE = tfplan

BACKEND_ARGS := \
	-backend-config="bucket=$(TF_STATE_BUCKET)" \
	-backend-config="key=$(TF_STATE_KEY)" \
	-backend-config="region=$(AWS_REGION)" \
	-backend-config="dynamodb_table=$(TF_LOCK_TABLE)" \
	-backend-config="encrypt=true"

terraform-init-migrate:
	$(TERRAFORM) init -migrate-state $(BACKEND_ARGS)

terraform-init:
	$(TERRAFORM) init $(BACKEND_ARGS)	

terraform-fmt:
	$(TERRAFORM) fmt -recursive

terraform-validate:
	$(TERRAFORM) validate

terraform-plan: terraform-init
	$(TERRAFORM) plan -out=$(PLAN_FILE)

terraform-apply:
	$(TERRAFORM) apply $(PLAN_FILE)

terraform-destroy:
	$(TERRAFORM) destroy

terraform-routine: terraform-plan terraform-apply

.PHONY: terraform-init terraform-fmt terraform-validate terraform-plan terraform-apply terraform-destroy terraform-routine

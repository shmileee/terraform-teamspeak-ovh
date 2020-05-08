ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

ANSIBLE_DEFAULT_INVENTORY?="./inventories/teamspeak/hosts"
ANSIBLE_TF_INVENTORY?="/usr/local/bin/terraform-inventory"

ANSIBLE_DEFAULT_PRIVATE_KEY?="~/.ssh/id_rsa"
SSH_USER?="ubuntu"

.PHONY: deploy
deploy: deps
	TF_STATE=$(shell dirname $(ROOT_DIR)) python3 -m pipenv run ansible-playbook \
	-i $(ANSIBLE_TF_INVENTORY) -i $(ANSIBLE_DEFAULT_INVENTORY) \
	--user $(SSH_USER) --private-key $(ANSIBLE_DEFAULT_PRIVATE_KEY) \
	--vault-password-file ~/.vault playbooks/site.yml

.PHONY: deps
deps:
	ansible-galaxy install -r requirements.yml

.PHONY: clean
clean:
	ansible-galaxy list | grep -v 'unknown version' | grep -o -P '(?<=-).*(?=,)' | xargs -I '{}' ansible-galaxy remove {}



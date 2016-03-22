validate = ! bundle exec kwalify -lf $1 | grep --after-context=1 INVALID
data     = $(subst .yml,,$(shell ls data))
name     = nucleotides/data

################################################
#
# Deploy data container
#
################################################

deploy: .image
	docker login --username=$$DOCKER_USER --password=$$DOCKER_PASS --email=$$DOCKER_EMAIL
	docker tag $(name) $(name):staging
	docker push $(name):staging

.image: $(shell find data -name '*.yml') Dockerfile
	docker build --tag=$(name) .
	touch $@

################################################
#
# Test data with the schema
#
################################################

types  = $(shell ls data/type)
inputs = $(types) data_source.yml

test: $(addprefix .test_token/,$(inputs))

.test_token/data_source.yml: schema/data_source.yml data/input_data/data_source.yml
	$(call validate,$^)
	@touch $@

.test_token/%: schema/metadata_type.yml data/type/%
	$(call validate,$^)
	@touch $@

################################################
#
# Bootstrap required resources
#
################################################

bootstrap: Gemfile.lock
	mkdir -p .test_token/type

Gemfile.lock: Gemfile
	bundle install

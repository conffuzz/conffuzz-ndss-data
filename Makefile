WORKDIR ?= $(CURDIR)
ORG     ?= conffuzz

all: paper-table

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

paper-table:
	cd $(mkfile_dir)/sandbox && $(mkfile_dir)/paper-figures-generators/generate-paper-table.sh
	cd $(mkfile_dir)/safebox && $(mkfile_dir)/paper-figures-generators/generate-paper-table.sh

paper-plots:
	$(mkfile_dir)/paper-figures-generators/generate-raw-data-functions.sh $(mkfile_dir) \
		> $(mkfile_dir)/paper-figures-generators/apivuln.dat
	cd $(mkfile_dir)/paper-figures-generators/ && gnuplot apivuln.plot
	$(mkfile_dir)/paper-figures-generators/generate-raw-data-types.sh $(mkfile_dir) \
		> $(mkfile_dir)/paper-figures-generators/typesvuln.dat
	cd $(mkfile_dir)/paper-figures-generators/ && gnuplot typesvuln.plot

sanitize-data-set:
	cd $(mkfile_dir)/sandbox && $(mkfile_dir)/data-set-sanitizers/fix-critical-sets.sh
	cd $(mkfile_dir)/sandbox && $(mkfile_dir)/data-set-sanitizers/determine-arbitrary.sh
	cd $(mkfile_dir)/safebox && $(mkfile_dir)/data-set-sanitizers/fix-critical-sets.sh
	cd $(mkfile_dir)/safebox && $(mkfile_dir)/data-set-sanitizers/determine-arbitrary.sh

# Prepare the final Zenodo archive
zenodo:
	#apt install jq
	mkdir -p $(WORKDIR)/repositories
	# clone all repos in the conffuzz organization
	cd $(WORKDIR)/repositories && \
		curl -s https://github.com:@api.github.com/orgs/${ORG}/repos?per_page=200 | \
		jq .[].ssh_url | xargs -n 1 git clone
	# remove this one otherwise we'd be duplicate
	rm -rf repositories/conffuzz-ndss-data
	tar -czf $(WORKDIR)/../conffuzz-artifact.tar.gz $(WORKDIR)

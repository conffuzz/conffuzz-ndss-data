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

# ConfFuzz NDSS Data-Set

[![](https://img.shields.io/badge/arXiv-paper-red)](https://arxiv.org/abs/2212.12904)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7509209.svg)](https://doi.org/10.5281/zenodo.7509209)

This repository contains a data set of CIVs generated by ConfFuzz.

**Link to the main ConfFuzz repository: [[Main Repository]](https://github.com/conffuzz/conffuzz)**

Each (application, library) tuple has its own folder under `sandbox` or `safebox`.

The paper provides an analysis of this data set.

## Data Set Processing

- Sanitizing the data set:

```
$ make sanitize-data-set
```

Ideally we shouldn't need this, but the fuzzer has a few bugs in its output of fuzzing metadata.

## Data Set Visualization

The Makefile provides rules to generate the paper's figures.

- Generating the paper's main table:

```
$ make paper-table
```

- Generating the paper's plots:

```
$ make paper-plots
```

The resulting plots are available under `paper-figures-generators/`.

## Other Scripts

### Data Set Analysis

- `data-set-analyzers/find-complex-crashes.sh`: can be used to find crashes that have more than one alteration.
- `data-set-analyzers/find-multi-impact.sh`: can be used to find crashes that have more than one impact.
- `data-set-analyzers/compare-outputs.sh`: can be used to merge two ConfFuzz `crashes/` folders.

The rest of scripts should not be needed.

### Data Set Sanitization

- `data-set-sanitizers/(de)compress-crashes.sh`: can be used to compress and decompress large crash output. This was necessary for Memcached.

The rest of scripts from `data-set-sanitizers/` are used by `make sanitize-data-set`.

## Generating Static/Manual API Usage Analysis (for Coverage)

Sometimes, ConfFuzz's static analysis can fail to find calls to API endpoints,
for a variety of reasons - static analysis is not perfect.

In this case we performed the rest of the analysis manuall. A few examples:

```
$ cat interfaces/cc/aspell.h | grep -v define |grep -Po " [^\s]+\(" | sort -u | wc -l
$ grep --include *.cc -rPo "(xml|html)[^\(:\s_\d\.]*\(" | sed "s/.*://g" | sort -u
$ grep --include *.c -rPo "(xml|html)[^\(:\s_]*\(" | sed "s/.*://g" | sort -u
```

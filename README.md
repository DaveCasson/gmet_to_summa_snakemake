# gmet to summa snakemake

## Table of Contents
- [Introduction](#introduction)
  - [Introduction to Snakemake](#introduction_to_snakemake)
- [Usage](#usage)
- [Acknowledgements](#acknowledgements)

## Introduction

This repository contains a Snakemake workflow for converting GMET meterological forcing data to SUMMA model input files.

The scripting for this workflow was developed by Andy Wood. It was adapted to snakemake and easymore by Dave Casson.


**Introduction to Snakemake**

Snakemake is a workflow management system that aims to reduce the complexity of creating workflows by providing a fast and comfortable execution environment, together with a clean and modern domain specific specification language (DSL) in Python style. It is widely used in bioinformatics for creating data analysis pipelines, but it's useful in any context where a series of steps (i.e., a workflow) needs to be performed on some input data to produce some output data.

Snakemake workflows consist of a set of rules, where each rule describes how to create a certain part of the output. The rules describe both what needs to be done (the actions or commands), and under what circumstances (the input files, output files, and conditions).

For example, consider the following rule from a Snakemake workflow:

```python
# Add Gregorian calendar to the time variable, needed for easymore
rule add_gregorian_to_nc:
    input:  
        input_forcing = Path(config['gmet_forcing_dir'],"{id}.nc")
    output:
        output_forcing = temp(Path(config['gmet_tmp_forcing_dir'],"{id}_greg.nc"))
    shell:
        'ncatted -a "calendar,time,o,c,"gregorian"" {input.input_forcing} {output.output_forcing}'
```

This rule, named `add_gregorian_to_nc`, describes a process where a NetCDF file (`{id}.nc`) is taken from a directory (`config['gmet_forcing_dir']`), and a command is executed on it (`ncatted -a "calendar,time,o,c,"gregorian""`). The result is a new, temporary NetCDF file (`{id}_greg.nc`), stored in a different directory (`config['gmet_tmp_forcing_dir']`). The rule uses Python's pathlib.Path to create path objects and Snakemake's built-in `temp` function to specify that the output file is a temporary file that can be deleted as soon as no other rule needs it as input.

A crucial feature of Snakemake is its ability to automatically determine the sequence of rules to execute based on their inputs and outputs, creating a directed acyclic graph (DAG). It checks which output files are missing, finds the rules that can generate them from existing files, and then recursively does this for the new inputs until it reaches files that already exist. It can parallelize rule execution, resume incomplete runs, and provides powerful features for reproducibility.


## Usage

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

## Acknowledgements

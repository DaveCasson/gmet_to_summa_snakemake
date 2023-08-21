# gmet to summa snakemake

Converting high-resolution ensemble meterological forcings to summa model input using snakemake, easymore and metsim.

![Auto-generated Workflow Schematic]('https://github.com/DaveCasson/gmet_to_summa_snakemake/blob/main/workflow/reports/gmet_to_summa.png')

## Table of Contents
- [Overview](#overview)
- [Introduction to Snakemake](#introduction_to_snakemake)
- [Getting Started](#getting_started)
- [Acknowledgements](#acknowledgements)

## Introduction

This repository contains a Snakemake workflow for converting GMET meterological forcing data to SUMMA model input files.

The scripting for this workflow was developed by Andy Wood. It was adapted to snakemake and easymore by Dave Casson.


**Introduction to Snakemake**

Snakemake is a workflow management system that aims to reduce the complexity of creating workflows by providing a fast and comfortable execution environment, together with a clean and modern domain specific specification language (DSL) in Python style. It is widely used in bioinformatics for creating data analysis pipelines, but it's useful in any context where a series of steps (i.e., a workflow) needs to be performed on some input data to produce some output data. The official website can be located [here](https://snakemake.github.io/).

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


## Getting Started


1. **Clone this git repository**

  Navigate to the local directory where the repo will be located. From your terminal, enter:

  `git clone https://github.com/DaveCasson/gmet_to_summa_snakemake.git`


2. **Set Up Virtual Environment (Optional)**  

    Enter the repo directory, and create a virtual environment.

   ```bash
   python -m venv gmet_to_summa
   source env/bin/activate  # For Windows, use `env\Scripts\activate`
   ```

3. **Install Dependencies**  
   ```bash
   pip install -r requirements.txt
   ```
4. **Install gmet_to_summa_snakemake as kernel**

```bash
ipython kernel install --name "gmet_to_summa_snakemake" --user
```
6. Install branch of MetSim

  An branch of MetSim is needed, due to an update in Pandas date time handling. [Details here](https://github.com/UW-Hydro/MetSim/pull/260)
  Navigate to the local directory where the repo will be located. From your terminal, enter:

  `git clone https://github.com/DaveCasson/MetSim`

  Enter the MetSim directory, and with the virtual environment activated

  `pip install .`

4. **Install nco**

  If not installed on your maching, [install nco](https://formulae.brew.sh/formula/nco).


4. **Navigate to the Notebooks Directory**  
   ```bash
   cd notebooks/
   ```

5. **Start Jupyter Notebook**  
   ```bash
   jupyter notebook
   ```

Instructions for running the snakemake workflows are located in the notebooks folder.


## Acknowledgements

Gmet data, and an original processing workflow was created by Andy Wood.

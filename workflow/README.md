# Snakemake workflows

This directory contains the recommended lay-out for Snakemake workflows.


## Repository Structure

- 📂 `notebooks/`: Collection of Jupyter Notebooks to write and run the snakemake files
- 📂 `rules/`: Snakemake rules (.smk files)
- 📂 `config/`: Settings files for configuring the workflow
- 📂 `scripts/`: Python scripts external to snakemake files
- 📂 `reports/`: Output figures and reports from the snakemake runs
- 📄 `gmet_to_summa.smk`: Master snakemake file for this workflow

## Running snakemake

Snakemake is run from the command line, as below:

`snakemake -s path/to/snakemake_file --configfile path/to/config_file.yaml`

There is an extensive list of Command Line options that add functionationilty, found by running  `snakemake -h`or [found online here](https://snakemake.readthedocs.io/en/stable/executing/cli.html).

## Initial Test Run - Using Jupyter notebooks

In development is convenient to both run the Snakemake files, and run them for testing in Jupyter notebooks. Navigate to the notebooks directory and open gmet_to_summa_snakemake.ipynb to see how this is done.

For initial testing of your Python environment, open the write_and_test_rules.ipynb workflow. Run the first snakemake file (../rules/gmet_file_prep.smk) from the notebook. This will be running the first few Jupyter notebook cells.

## Running the complete workflow

Open the Jupyter notebook gmet_to_summa_snakemake.ipynb and run the first view cells. This will attempt to run the complete workflow, which should take around 1 minute.

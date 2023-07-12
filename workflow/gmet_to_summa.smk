''' 
gmet to summa snakemake master snakemake file

This snakemake file runs all the steps required to convert GMET forcings to SUMMA forcings.

Original process code: Andy Wood
Adapted to Snakemake: Dave Casson
'''

include: './rules/gmet_file_prep.smk'
include: './rules/remap_gmet_to_shp.smk'
include: './rules/metsim_file_prep.smk'
include: './rules/run_metsim.smk'
include: './rules/metsim_to_summa.smk'

def build_ensemble_list(directory):
    ''' Build a list of the ensemble name and the file name for each file in the directory
        e.g. for each file in the directory: ens_forc.tuolumne.01d.2020.001.nc' --> 001/ens_forc.tuolumne.01d.2020.001.nc
    '''
    
    path = Path(directory)
    files = path.glob('*') 
    ensemble_list = set()  

    for file in files:
        if file.exists():
            filename = file.stem  # Get the filename without the extension
            directory_name = filename[-3:]  # Get the last three characters
            ensemble_list.add(Path(directory_name, filename)) # Create and add the ens/filename.nc path

    return ensemble_list

# Read all forcing files and create a list based on the output directory (i.e. ens/filename.nc)
ensemble_list = build_ensemble_list(config['forcing']['forcing_dir'])

rule gmet_to_summa:
    input:
        expand(Path(config['summa']['summa_forcing_dir'],'{forcing_file}.nc'), forcing_file = ensemble_list)
        

"""

Remapping of forcing files to catchment hrus using easymore

"""


import netCDF4 as nc4
from pathlib import Path
from easymore import easymore


def rename_easymore_output(esmr):
    """Rename easymore output to original filename"""

    # Read data from easymore object.
    # Strict output formatting is done by easymore
    forcing_input = Path(esmr.source_nc)
    forcing_input_ds = nc4.Dataset(forcing_input)
    time_var = forcing_input_ds[esmr.var_time][:]
    time_unit = forcing_input_ds.variables[esmr.var_time].units
    time_cal = forcing_input_ds.variables[esmr.var_time].calendar
    target_date_times = nc4.num2date(time_var, units=time_unit, calendar=time_cal)

    easymore_output = Path(
        esmr.output_dir,
        f'{esmr.case_name}_remapped_{target_date_times[0].strftime("%Y-%m-%d-%H-%M-%S")}.nc',
    )

    easymore_output.rename(Path(easymore_output.parent,forcing_input.name))


def remap_with_easymore(
    config, input_forcing, input_shp, remap_file, only_create_remap_csv=False, file_path=None):

    print(f'INPUT FORCING: {input_forcing}')
    # initializing EASYMORE object
    esmr = easymore()

    # specifying EASYMORE objects
    # name of the case; the temporary, remapping and remapped file names include case name
    esmr.case_name = config["case_name"]
    # temporary path that the EASYMORE generated GIS files and remapped file will be saved
    esmr.temp_dir = str(config["easymore_temp_dir"])+"/"
    # name of target shapefile that the source netcdf files should be remapped to
    esmr.target_shp = input_shp
    esmr.remapped_dim_id = "hru"  # name of the non-time dimension; prescribed by SUMMA
    esmr.remapped_var_id = "hruId"  # name of the variable associated with the non-time dimension
    esmr.target_shp_ID = config["catchment_shp_hru_id_field"]  # name of the HRU ID field
    esmr.target_shp_lat = config["catchment_shp_lat_id_field"]  # name of the latitude field
    esmr.target_shp_lon = config["catchment_shp_lon_id_field"]  # name of the longitude field
    # name of netCDF file(s); multiple files can be specified with *
    esmr.source_nc = input_forcing
    # name of variables from source netCDF file(s) to be remapped
    esmr.var_names = config["gmet_input_var"]
    # name of variable longitude in source netCDF files
    esmr.var_lon = "longitude"
    # name of variable latitude in source netCDF files
    esmr.var_lat = "latitude"
    # name of variable time in source netCDF file; should be always time
    esmr.var_time = "time"
    # location where the remapped netCDF file will be saved
    if file_path is None:
        ens_member_str = None
        esmr.output_dir = str(config["easymore_output_dir"]) + "/"
    else:
        #file_path_str = file_path.pop()
        ens_member_str = file_path[:3]
        esmr.output_dir = str(config["easymore_output_dir"]) + "/" + ens_member_str + "/"
    # format of the variables to be saved in remapped files,
    # if one format provided it will be expanded to other variables
    esmr.format_list = ["f4"]
    # fill values of the variables to be saved in remapped files,
    # if one value provided it will be expanded to other variables
    esmr.fill_value_list = ["-9999.00"]
    # if exists and uncommented EASYMORE will use this remapping info and skip GIS tasks
    esmr.remap_csv = remap_file

    if only_create_remap_csv:
        # update the status of easymore, so the GIS tasks will be skipped in following calculation
        esmr.remap_csv = ""
        # Name of column id in shp file
        esmr.target_shp_ID = config["easymore"]["catchment_shp_hru_id_field"]
        esmr.only_create_remap_csv = True
        # execute EASYMORE
        print('Creating remap csv')
        esmr.nc_remapper()
        print('Creating remap csv complete')
        # execute EASYMORE
    else:
        esmr.remap_csv = remap_file
        print('Starting remapping')
        esmr.nc_remapper()
        rename_easymore_output(esmr)

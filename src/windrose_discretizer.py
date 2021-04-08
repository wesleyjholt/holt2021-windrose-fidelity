
from ruamel.yaml import YAML as _yaml
import xarray as _xr
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm

def discretize_windrose_iea37(input_filename, output_filename, ndirs, input_directory="", output_directory=""):

    #---- load original wind resource ----
    with open(input_directory + input_filename) as f:
        _yaml.allow_duplicate_keys = True
        wind_res_orig = _yaml(typ='safe').load(f)

    #---- extract data from structure ----
    props_orig = wind_res_orig['definitions']['wind_inflow']['properties']
    directions_orig = props_orig['direction']['bins']
    direction_pmf_orig = props_orig['direction']['frequency']
    speeds_orig = props_orig['speed']['bins']
    speed_cpmf_orig = props_orig['speed']['frequency']

    #---- create xarray dataset ----
    ds_orig = _xr.Dataset(
        data_vars={'direction_pmf': ('direction', direction_pmf_orig),
                'speed_cpmf': (('direction', 'speed'), speed_cpmf_orig)},
        coords={'direction': directions_orig, 'speed': speeds_orig}
    )

    #---- create cyclical dataset ----
    # get wind directions
    dirs = ds_orig.coords['direction']
    # add extra element to end of wind directions
    dirs_cyc = _xr.concat([dirs, dirs[0]], 'direction')
    # copy the original dataset, but with the new directions vector
    ds_cyc = ds_orig.sel({'direction': dirs_cyc})
    # add 360 to the added wind direction
    dirs_cyc[-1] += 360.0
    # save the new vector to the cyclical dataset
    ds_cyc.coords['direction'] = dirs_cyc

    #---- interpolate & normalize ----
    # linearly interpolate the pmf to specified number of wind directions (instead of 20)
    ds = ds_cyc.interp(direction=np.linspace(0, 360*(ndirs-1)/ndirs, ndirs), method='linear')
    # normalize the resulting distribution to make it a pdf (so that the sum of all probabilities equals one)
    ds['direction_pmf'] /= ds.direction_pmf.sum('direction')

    #---- create output data structure ----
    props = props_orig
    props['direction']['bins'] = ds.direction.values.tolist()
    props['direction']['frequency'] = ds.direction_pmf.values.tolist()
    props['speed']['bins'] = ds.speed.values.tolist()
    props['speed']['frequency'] = ds.speed_cpmf.values.tolist()
    wind_res = wind_res_orig
    wind_res['definitions']['wind_inflow']['properties'] = props

    #---- modify description ----
    wind_res['description'] = (
        "Wind resource conditions, modified from IEA37 WFLO case study 3 to have " + str(ndirs) + " wind direction bins.")

    #---- write out interpolated wind resource ----
    with open(output_directory + output_filename, "w") as f:
        _yaml(typ='safe').dump(wind_res, f)

def plot_windrose_polar_iea37(input_filename, output_filename, input_directory="", output_directory="", show_fig=True, save_fig=False):
    
    #### ---- import and organize the data ----

    # load original wind resource
    with open(input_directory + input_filename) as f:
        _yaml.allow_duplicate_keys = True
        wind_res_orig = _yaml(typ='safe').load(f)
    # extract data from structure
    props_orig = wind_res_orig['definitions']['wind_inflow']['properties']
    # direction bins
    directions = props_orig['direction']['bins']
    # direction probability mass function
    direction_pmf = np.array(props_orig['direction']['frequency'])
    # speed bins
    speeds = props_orig['speed']['bins']
    # speed probability mass functions
    speed_cpmf = np.array(props_orig['speed']['frequency'])
    # get number of wind directions and speeds
    ndirs = len(directions)
    nspeeds = len(speeds)
    print("Directions: ", directions, "\n")
    print("Directions Probabilities: ", direction_pmf, "\n")
    print("Speeds: ", speeds, "\n")
    print("Speed Probabilities: ", speed_cpmf, "\n")

    
    #### ---- create synthetic direction and speed data for the plots ----

    # Both the direction and speed figure data vectors will have ndirs*1e4 elements. The values in these vectors 
    # will be taken from the specified direction and speed bins. The amount of times each direction and speed value 
    # appear will depend on the respective probability distributions. These vectors will then be used to create the
    # wind rose plots.

    # initialize direction and speed figure data vectors
    directions_figuredata = []
    speeds_figuredata = []
    # calculate how many times each wind direction bin will show up as an element in the directions_figuredata vector
    nvalues_in_direction_bins = np.round(direction_pmf*ndirs*1e5).astype(np.int)
    # iterate through each wind direction
    for d in np.arange(ndirs):
        # assign the direction bin value to a precalculated amount of elements in the directions_figuredata vector
        directions_figuredata += [directions[d]]*nvalues_in_direction_bins[d]
        # calculate how many times each wind speed bin will show up as an element in the speeds_figuredata vector for this wind direction
        nvalues_in_speed_bins = np.round(speed_cpmf[d]*nvalues_in_direction_bins[d]).astype(np.int)
        # fix any discrepancies between the number of allocated elements for this direction in the directions_figuredata and speeds_figuredata
        while_counter = 0
        while sum(nvalues_in_speed_bins) != nvalues_in_direction_bins[d]:
            if while_counter > 1000:
                raise ValueError('Got stuck in the while loop trying to get the speed and direction vectors to match in size.')
            if sum(nvalues_in_speed_bins) > nvalues_in_direction_bins[d]:
                nvalues_in_speed_bins[while_counter % nspeeds] -= 1
            else:
                nvalues_in_speed_bins[while_counter % nspeeds] += 1
        # iterate through each wind speed
        for s in np.arange(nspeeds):
            # assign the speed bin value to a precalculated amount of elements in the speeds_figuredata vector
            speeds_figuredata += [speeds[s]]*nvalues_in_speed_bins[s]
    # convert the figure data lists to numpy arrays
    directions_figuredata = np.array(directions_figuredata)
    speeds_figuredata = np.array(speeds_figuredata)
    
    #### ---- create an array with the size of each bin on the wind rose plot ----

    # set the values for the edges of the direction bins
    directionRes = directions[1] - directions[0]    # this assumes all the direction bins are evenly spaced, which they should be
    directionEdges = np.append(directions, directions[0] + 360) - directionRes/2
    # set the values for the edges of the speed bins
    speedEdges = np.zeros(nspeeds+1)
    speedEdges[-1] = round(speeds[-1] + (speeds[-1] - speeds[-2])/2, 1)
    for s in np.arange(nspeeds-1):
        speedEdges[s+1] = round((speeds[s] + speeds[s+1])/2, 1)
    # create bin size data
    binsizes,_,_ = np.histogram2d(speeds_figuredata, directions_figuredata, np.array([speedEdges, directionEdges]))
    # normalize the bin sizes
    p = binsizes/np.sum(binsizes)
    print(p)

    #### ---- create the wind rose plot ----

    # create blank figure
    fig = plt.figure(figsize=(8,8))
    # set location of windrose on the figure and change coordinate type to polar
    ax = fig.add_axes(([0.07,0.15,0.725,0.725]), polar=True)
    # set the direction of increasing theta to be clockwise
    ax.set_theta_direction(-1)
    # set theta to start at the vertical axis 
    ax.set_theta_offset(np.pi/2.0)
    # set color map
    blues = cm.get_cmap("Blues")(np.array(speeds[::-1])/speeds[-1])
    # initialize lists to hold info for the legend
    bars = list()
    legend_labels = list()
    # iterate through each wind speed
    for i in range(0,len(speedEdges)-1):
        # plot the bars associated with this wind speed
        b = plt.bar(np.radians(directions), p[i,:], width=np.radians(directionRes-5./np.sqrt(ndirs)), color=blues[i])
        # update legend info
        bars.append(b)
        legend_labels.append(str(np.round(speeds[nspeeds-i-1],1)) + " m/s")
    # add legend
    plt.legend(bars, legend_labels, loc=(1.07,.15))
    # title the wind rose plot
    plt.title("Wind Rose with " + str(ndirs) + " Directions")

    if save_fig:
        plt.savefig(output_directory + output_filename, dpi=600)

    if show_fig:
        plt.show()

def create_new_windrose_file_iea37(ndirs_vec):
    
    # setup input file
    input_directory = "windrose-files/"
    input_filename = "iea37-windrose-cs3.yaml"

    # setup and create output file(s)
    output_directory = "windrose-files/"
    for ndirs in ndirs_vec:
        output_filename = "iea37-windrose-" + str(ndirs).rjust(3,'0') + "dirs.yaml"
        discretize_windrose_iea37(input_filename, output_filename, ndirs, input_directory=input_directory, output_directory=output_directory)

def create_new_windrose_plot_iea37(ndirs_vec):
    
    # set up input and output files, and create the plots
    input_directory = "windrose-files/"
    output_directory = "windrose-files/windrose-figures/"
    for ndirs in ndirs_vec:
        input_filename = "iea37-windrose-" + str(ndirs).rjust(3,'0') + "dirs.yaml"
        output_filename = "iea37-windrose-" + str(ndirs).rjust(3,'0') + "dirs.png"
        plot_windrose_polar_iea37(input_filename, output_filename, input_directory=input_directory, output_directory=output_directory, show_fig=False, save_fig=True)

# ---- These are the only value that need to be changed. ----
create_new_windrose_file = False
create_new_windrose_plot = False
ndirs_vec = [30] #[20, 50, 100, 200, 360]
# -----------------------------------------------------------

if create_new_windrose_file:
    create_new_windrose_file_iea37(ndirs_vec)
if create_new_windrose_plot:
    create_new_windrose_plot_iea37(ndirs_vec)

ndirs_vec = [12, 36, 72, 120, 360]
nspeeds_vec = [2, 5, 10, 25, 50]
def create_new_windrose_plot_hornsrev(ndirs_vec, nspeeds_vec):
    
    # set up input and output files, and create the plots
    input_directory = "../data/windrose-files/horns-rev/"
    output_directory = "../data/windrose-files/horns-rev-figures/"
    for ndirs in ndirs_vec:
        for nspeeds in nspeeds_vec:
            input_filename = "horns-rev-windrose-" + str(ndirs).rjust(3,'0') + "dirs-" + str(nspeeds).rjust(2,'0') + "speeds.yaml"
            output_filename = "horns-rev-windrose-" + str(ndirs).rjust(3,'0') + "dirs-" + str(nspeeds).rjust(2,'0') + "speeds.png"
            plot_windrose_polar_iea37(input_filename, output_filename, input_directory=input_directory, output_directory=output_directory, show_fig=False, save_fig=True)

create_new_windrose_plot_hornsrev(ndirs_vec, nspeeds_vec)

# TODO: Create a pdf plot of a wind speed for a direction that shows the different colors used on the wind rose.


# # create windrose plot from IEA Task 37 Case Study 4 for comparison
# input_directory = "windrose-files/"
# output_directory = "windrose-files/windrose-figures/"
# input_filename = "iea37-windrose-cs4.yaml"
# output_filename = "iea37-windrose-cs4.png"
# plot_windrose_polar_iea37(input_filename, output_filename, input_directory=input_directory, output_directory=output_directory, show_fig=False, save_fig=True)

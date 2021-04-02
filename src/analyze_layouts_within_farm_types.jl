using YAML
using DelimitedFiles
using PyPlot

# =============================================================================================
# =================================== INPUT ARGUMENTS =========================================
# =============================================================================================

# -------- number of turbines, boundary type, boundary radius, optimization algorithm ---------

nturbines_string = string(ARGS[1])
boundary_type = string(ARGS[2])
if boundary_type == "circle"
    boundary_radius_string = lpad(ARGS[3], 3, "0")
    boundary_radius = Base.parse(Float64, ARGS[3])
end
opt_algorithm = string(ARGS[4])

# =============================================================================================
# ===================================== AEP WRAPPER ===========================================
# =============================================================================================

function aep_wrapper(x, params)

    # get number of turbines
    nturbines = Int(length(x)/2)

    # extract x and y locations of turbines from design variables vector
    turbine_x = x[1:nturbines] 
    turbine_y = x[nturbines+1:end]

    # calculate AEP
    AEP = obj_scale*ff.calculate_aep(turbine_x, turbine_y, params.turbine_z, params.rotor_diameter,
                params.hub_height, params.turbine_yaw, params.ct_models, params.generator_efficiency, params.cut_in_speed,
                params.cut_out_speed, params.rated_speed, params.rated_power, params.windresource, params.power_models, params.model_set,
                rotor_sample_points_y=params.rotor_points_y,rotor_sample_points_z=params.rotor_points_z)
    
    # return the objective as an array
    return [AEP]
end


# =============================================================================================
# ================================ SET FLOWFARM PARAMETERS ====================================
# =============================================================================================

# set globals for use in wrapper functions
struct params_struct{MS, AF, F, I, ACTM, WR, APM}
    model_set::MS
    rotor_points_y::AF
    rotor_points_z::AF
    turbine_z::AF
    rotor_diameter::AF
    boundary_center::AF
    boundary_radius::F
    obj_scale::I
    hub_height::AF
    turbine_yaw::AF
    ct_models::ACTM
    generator_efficiency::AF
    cut_in_speed::AF
    cut_out_speed::AF
    rated_speed::AF
    rated_power::AF
    windresource::WR
    power_models::APM
end

# set ndirs and layout number
ndirs = 360 # this number matters for the analysis
layout_number = 1 # this number doesn't matter
farm_type = nturbines_string * "turb-circle-" * boundary_radius_string * "r"

# set directory and file names (must do this before including the model set file)
layout_directory = "initial-layouts/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radius_string * "r/"
layout_filename = "initial-layout-001.txt"
windrose_directory = "windrose-files/nantucket/"
windrose_filename = "nantucket-windrose-ave-speeds-" * lpad(ndirs,3,"0") * "dirs.txt"

# import model set with wind farm and related details
include("model-sets/model_set_9turb_round_farm.jl")

# scale objective so the AEP output is in MWh
obj_scale = 1E-6

# set wind farm boundary parameters
boundary_center = [0.0,0.0]

# initialize struct for opt params
params = params_struct(model_set, rotor_points_y, rotor_points_z, turbine_z, 
    rotor_diameter, boundary_center, boundary_radius, obj_scale, hub_height, turbine_yaw, 
    ct_models, generator_efficiency, cut_in_speed, cut_out_speed, rated_speed, rated_power, 
    windresource, power_models)


# =============================================================================================
# ============================== SET OPTIONS FOR ANALYSIS =====================================
# =============================================================================================

# determine whether to plot
plot=true

# set up
initial_layout_directory = "initial-layouts/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radius_string * "r/"
nlayouts = 50
max_layouts_plot = 20
ndirs_vec = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120, 150, 200, 360]

# initialize arrays to hold layout and aep values
layouts = zeros(nlayouts, length(ndirs_vec), nturbines*2)
aeps_initial_layouts = zeros(nlayouts, length(ndirs_vec))
aeps_initial_layouts_360dirs = zeros(nlayouts, length(ndirs_vec))
aeps_final_layouts = zeros(nlayouts, length(ndirs_vec))
aeps_final_layouts_360dirs = zeros(nlayouts, length(ndirs_vec))


# =============================================================================================
# =============================== ANALYZE AND PLOT LAYOUTS ====================================
# =============================================================================================

# ------------- CALCULATE AEP AND PLOT LAYOUTS ACCORDING TO THE LAYOUT NUMBER -----------------

# iterate through layouts
for layout_number = 1:nlayouts
    if layout_number <= max_layouts_plot
        # initialize plot
        clf()
        # add wind farm boundary to plot
        plt.gcf().gca().add_artist(plt.Circle((boundary_center[1],boundary_center[2]), boundary_radius, fill=false, color="black"))
        # set up and show plot
        axis("square")
        title("Layout " * lpad(layout_number,3,"0"))
        xlim(boundary_center[1] - boundary_radius*1.3, boundary_center[1] + boundary_radius*1.3)
        ylim(boundary_center[2] - boundary_radius*1.3, boundary_center[1] + boundary_radius*1.3)
    end

    # iterate through number of directions
    for (i, ndirs_reference) in enumerate(ndirs_vec)
        # set layout directory and file names
        final_layout_directory = "final-layouts/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radius_string * "r/" * opt_algorithm * "/" * lpad(ndirs_reference,3,"0") * "dirs/"
        initial_layout_filename = "initial-layout-" * lpad(layout_number,3,"0") * ".txt"
        final_layout_filename = "final-layout-" * lpad(layout_number,3,"0") * ".yaml"

        # get final layout
        final_data = YAML.load_file(final_layout_directory * final_layout_filename)
        aeps_final_layouts[layout_number,i] = final_data["definitions"]["plant_energy"]["properties"]["annual_energy_production"]["default"]
        nturbines = length(final_data["definitions"]["position"]["items"])
        for k = 1:2, j = 1:nturbines
            layouts[layout_number, i, (k-1)*nturbines+j] = final_data["definitions"]["position"]["items"][j][k]
        end
        layout = layouts[layout_number, i, :]

        if layout_number <= max_layouts_plot
            # add turbine locations to plot
            for j = 1:nturbines
                plt.gcf().gca().add_artist(plt.Circle((layout[j], layout[j+nturbines]), rotor_diameter[1]/2.0, linewidth=0.0, fill=true, color="C0", alpha=.2)) 
            end
        end

        # calculate aep using 360 directions
        aeps_final_layouts_360dirs[layout_number,i] = aep_wrapper(layout, params)[1]
    end

    if layout_number <= max_layouts_plot
        # save figure
        savefig("final-layouts/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radius_string * "r/" * "figures/final-layouts-" * lpad(layout_number,3,"0") * ".png", dpi=600)
    end
end

# -------------- PLOT THE LAYOUTS ACCORDING TO THE NUMBER OF WIND DIRECTIONS ------------------

# iterate through each number of wind directions
for (i, ndirs_reference) in enumerate(ndirs_vec)
    # plot layouts by number of directions used for optimization
    figure()
    # add wind farm boundary to plot
    plt.gcf().gca().add_artist(plt.Circle((boundary_center[1],boundary_center[2]), boundary_radius, fill=false, color="black"))
    # set up and show plot
    axis("square")
    title(string(ndirs_reference) * " wind directions")
    xlim(boundary_center[1] - boundary_radius*1.3, boundary_center[1] + boundary_radius*1.3)
    ylim(boundary_center[2] - boundary_radius*1.3, boundary_center[1] + boundary_radius*1.3)
    # iterate through the layouts
    for layout_number = 1:nlayouts
        # add turbine locations to plot
        layout = layouts[layout_number, i, :]
        for j = 1:nturbines
            plt.gcf().gca().add_artist(plt.Circle((layout[j], layout[j+nturbines]), rotor_diameter[1]/2.0, linewidth=0.0, fill=true, color="C0", alpha=.05)) 
        end
    end
    # save figure
    savefig("final-layouts/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radius_string * "r/" * "figures/" * string(ndirs_reference) * "dirs-final-layouts.png", dpi=600)
end

# --------------------------- PLOT ALL LAYOUTS ONTO A SINGLE PLOT -----------------------------

figure()
# add wind farm boundary to plot
plt.gcf().gca().add_artist(plt.Circle((boundary_center[1],boundary_center[2]), boundary_radius, fill=false, color="black"))
# set up and show plot
axis("square")
title("All optimized layouts")
xlim(boundary_center[1] - boundary_radius*1.3, boundary_center[1] + boundary_radius*1.3)
ylim(boundary_center[2] - boundary_radius*1.3, boundary_center[1] + boundary_radius*1.3)
# iterate through number of directions
for (i, ndirs_reference) in enumerate(ndirs_vec)
    # iterate through layouts
    for layout_number = 1:nlayouts
        # add turbine locations to plot
        layout = layouts[layout_number, i, :]
        for j = 1:nturbines
            plt.gcf().gca().add_artist(plt.Circle((layout[j], layout[j+nturbines]), rotor_diameter[1]/2.0, linewidth=0.0, fill=true, color="C0", alpha=.007)) 
        end
    end
end
# save figure
savefig("results/figures/" * nturbines_string * "turb-" * boundary_type * "-" * boundary_radius_string * "-final-layouts.png", dpi=600)


# =============================================================================================
# ================================= PLOT THE AEP VALUES =======================================
# =============================================================================================

# -------------- PLOT AEP (CALCULATED WITH THE DIFFERENT NUMBERS OF DIRECTIONS) ---------------
fig = plt.figure()
ax = fig.add_axes([0.15, 0.1, 0.8, 0.8])
plt.boxplot(aeps_final_layouts)
plt.title("AEP for $nturbines_string-turbine circular farm \n($nlayouts for each wind rose)")
plt.xlabel("Number of Wind Directions")
plt.ylabel("AEP (MWh)")
ax.set_xticklabels(ndirs_vec)
savefig("results/figures/aepboxplots-" * nturbines_string * "turb-" * boundary_type * "-" * boundary_radius_string * "r.png" , dpi=600)
# plt.show()

# ----------------- PLOT AEP (CALCULATED WITH THE 360 NUMBERS OF DIRECTIONS) ------------------
fig = plt.figure()
ax = fig.add_axes([0.15, 0.1, 0.8, 0.8])
plt.boxplot(aeps_final_layouts_360dirs)
plt.title("AEP for $nturbines_string-turbine circular farm calculated with 360 directions \n($nlayouts for each wind rose)")
plt.xlabel("Number of Wind Directions")
plt.ylabel("AEP (MWh)")
ax.set_xticklabels(ndirs_vec)
savefig("results/figures/aepboxplots-" * nturbines_string * "turb-" * boundary_type * "-" * boundary_radius_string * "r-recalc.png" , dpi=600)
# plt.show()

# ------------------------------------- PLOT AEP ERROR ----------------------------------------
aep_final_layouts_error = (aeps_final_layouts .- aeps_final_layouts_360dirs) ./ aeps_final_layouts_360dirs   # calculate errors
fig = plt.figure()
ax = fig.add_axes([0.15, 0.1, 0.8, 0.8])
plt.boxplot(aep_final_layouts_error)
plt.title("AEP Error for $nturbines_string-turbine circular farm (compared with 360 directions) \n($nlayouts for each wind rose)")
plt.xlabel("Number of Wind Directions")
plt.ylabel("Error")
ax.set_xticklabels(ndirs_vec)
savefig("results/figures/aepboxplots-" * nturbines_string * "turb-" * boundary_type * "-" * boundary_radius_string * "r-error.png" , dpi=600)
# plt.show()


# =============================================================================================
# ======================== SAVE AEP/LAYOUTS VALUES IN A TEXT FILE =============================
# =============================================================================================

open("results/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radius_string * "r/aeps_final_layouts.txt", "w") do io
    write(io, "# Final AEP values, calculated using the repective directions\n# dirs=10,20,30,40,50,60,70,80,90,100,120,150,200,360\n")
    writedlm(io, aeps_final_layouts)
end

open("results/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radius_string * "r/aeps_final_layouts_360dirs.txt", "w") do io
    write(io, "# Final AEP values, recalculated using 360 directions\n# dirs=10,20,30,40,50,60,70,80,90,100,120,150,200,360\n")
    writedlm(io, aeps_final_layouts_360dirs)
end

open("results/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radius_string * "r/aep_final_layouts_error.txt", "w") do io
    write(io, "# AEP error between lower fidelity and 360-direction wind rose\n# dirs=10,20,30,40,50,60,70,80,90,100,120,150,200,360\n")
    writedlm(io, aep_final_layouts_error)
end

# open("results/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radius_string * "r/layouts.txt", "w") do io
#     write(io, "# layouts \n# dirs=10,20,30,40,50,60,70,80,90,100,120,150,200,360\n")
#     for i = 
#     writedlm(io, aep_final_layouts_error)
# end
using YAML
using DelimitedFiles
using PyPlot
using Statistics

# =============================================================================================
# =================================== INPUT ARGUMENTS =========================================
# =============================================================================================

# --------------- number of turbines, boundary type, optimization algorithm -----------------==

nturbines_string = string(ARGS[1])
boundary_type = string(ARGS[2])
if boundary_type == "circle"
    boundary_radii = reshape(readdlm(IOBuffer(ARGS[3]), ',', Int), :)
    boundary_radii_string = lpad.(boundary_radii, 3, "0")
end
opt_algorithm = string(ARGS[4])


# =============================================================================================
# ================================ READ IN RESULTS FILES ======================================
# =============================================================================================

# get the required size of the AEP arrays
aeps_final_layouts = readdlm("results/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radii_string[1] * "r/aep_final_layouts.txt", skipstart=2)
nlayouts, ndirs = size(aeps_final_layouts)
nradii = length(boundary_radii_string)

# initialize arrays to hold all AEP values
aeps_final_layouts = zeros(nlayouts, ndirs, nradii)
aeps_final_layouts_360dirs = zeros(nlayouts, ndirs, nradii)
aep_final_layouts_error = zeros(nlayouts, ndirs, nradii)

# populate the arrays with the precomputed AEP values
for i = 1:nradii
    aeps_final_layouts[:,:,i] = readdlm("results/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radii_string[i] * "r/aep_final_layouts.txt", skipstart=2)
    aeps_final_layouts_360dirs[:,:,i] = readdlm("results/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radii_string[i] * "r/aeps_final_layouts_360dirs.txt", skipstart=2)
    aep_final_layouts_error[:,:,i] = readdlm("results/" * nturbines_string * "turb/" * boundary_type * "/" * boundary_radii_string[i] * "r/aep_final_layouts_error.txt", skipstart=2)
end

# find the means of each AEP metric
aeps_final_layouts_mean = mean(aeps_final_layouts, dims=1)
aeps_final_layouts_360dirs_mean = mean(aeps_final_layouts_360dirs, dims=1)
aep_final_layouts_error_mean = mean(aep_final_layouts_error, dims=1)

# find the standard deviations of each AEP metric
aeps_final_layouts_std = std(aeps_final_layouts, dims=1)
aeps_final_layouts_360dirs_std = std(aeps_final_layouts_360dirs, dims=1)
aep_final_layouts_error_std = std(aep_final_layouts_error, dims=1)

# get normalized mean and std for the AEPs calculated with 360 directions
println(size(aeps_final_layouts_360dirs))
println(mean(aeps_final_layouts_360dirs[:,end,:], dims=1))
aeps_final_layouts_360dirs_norm = aeps_final_layouts_360dirs ./ mean(aeps_final_layouts_360dirs[:,end:end,:], dims=1)
aeps_final_layouts_360dirs_norm_mean = mean(aeps_final_layouts_360dirs_norm, dims=1)
aeps_final_layouts_360dirs_norm_std = std(aeps_final_layouts_360dirs_norm, dims=1)
# println(aeps_final_layouts_360dirs_norm_mean)
# println(aeps_final_layouts_360dirs_norm_std)
# println(size(aeps_final_layouts_360dirs_norm_mean))
# println(size(aeps_final_layouts_360dirs_norm_std))
println()

# =============================================================================================
# ============================ CREATE AEP CONVERGENCE PLOTS ===================================
# =============================================================================================


# # ------------------------ PLOT MEAN AEP, NORMALIZED BY MEAN AEP ------------------------------
# fig = plt.figure()
# ax = fig.add_axes()
# ndirs_vec = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120, 150, 200, 360]
# for i = 1:nradii
#     aeps = reshape(aeps_final_layouts_360dirs_norm_mean[:,:,i],:)
#     plt.plot(ndirs_vec, aeps)
# end
# plt.title("Mean Normalized AEP\n($nlayouts for each farm size/wind rose combination)")
# plt.xlabel("Number of Wind Directions")
# plt.ylabel("AEP / (optimal AEP optimized)")
# plt.legend(boundary_radii_string, title="Circular Boundary Radius")
# savefig("results/" * nturbines_string * "turb/" * boundary_type * "/aep_convergence_plot_mean_normalized.png" , dpi=600)
# # plt.show()

# ----------------- PLOT MEAN AEP, NORMALIZED BY 360 DIRECTIONS AEP MEAN ----------------------
fig = plt.figure()
ax = fig.add_axes()
ndirs_vec = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120, 150, 200, 360]
for i = 1:nradii
    aeps = reshape(aeps_final_layouts_360dirs_norm_mean[:,:,i],:)
    plt.plot(ndirs_vec, aeps)
end
plt.title("Mean Normalized AEP\n($nlayouts for each farm size/wind rose combination)")
plt.xlabel("Number of Wind Directions")
plt.ylabel("AEP / (AEP optimized with 360 directions)")
plt.legend(boundary_radii_string, title="Circular Boundary Radius")
savefig("results/" * nturbines_string * "turb/" * boundary_type * "/aep_convergence_plot_mean_normalized_360.png" , dpi=600)
# plt.show()

# ------------------------- PLOT MEAN AND STANDARD DEVIATION AEP ------------------------------
fig = plt.figure()
ax = fig.add_axes()
ndirs_vec = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120, 150, 200, 360]
for i = 1:nradii
    aeps = reshape(aeps_final_layouts_360dirs_mean[:,:,i],:)
    aep_errorbars = reshape(aeps_final_layouts_360dirs_std[:,:,i],:)
    plt.errorbar(ndirs_vec, aeps, yerr=aep_errorbars)
end
plt.title("AEP, calculated using 360 directions, mean and st. dev.\n($nlayouts for each farm size/wind rose combination)")
plt.xlabel("Number of Wind Directions")
plt.ylabel("AEP (MWh)")
plt.legend(boundary_radii_string, title="Circular Boundary Radius")
savefig("results/" * nturbines_string * "turb/" * boundary_type * "/aep_convergence_plot_meanstd.png" , dpi=600)
# plt.show()
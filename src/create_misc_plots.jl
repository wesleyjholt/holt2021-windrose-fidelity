include("sunflower_points.jl")
include("windrose_discretizer.jl")
using PyPlot

###########################################################################################
# CREATE FARM BOUNDARY AND SPACING PLOT
###########################################################################################

turbine_spacing = [5, 7.5, 10]
nturbines = [9, 16]
rotor_diameter = 80
clf()
fig = figure(figsize=(4,6))
# axis("off")

for row = 1:length(turbine_spacing)
    for col = 1:length(nturbines)
        circle_boundary_radius = calc_circle_boundary_radius(turbine_spacing[row], nturbines[col], rotor_diameter, 2)
        x,y = sunflower_points(nturbines[col]) .* circle_boundary_radius
        ax = fig.add_axes([0.15 + (col-1)*0.4, 0.02 + (3-row)*0.3, 0.4, 0.3])
        plt.gcf().gca().add_artist(plt.Circle((0.0,0.0), circle_boundary_radius/rotor_diameter, fill=false, alpha=0.3))
        for i = 1:length(x)
            plt.gcf().gca().add_artist(plt.Circle((x[i]/rotor_diameter, y[i]/rotor_diameter), 1/2, fill=true, color="C0"))
        end
        if row == 1
            title("$(nturbines[col]) Turbines", fontsize=16)
        end
        if col == 1
            turbine_spacing_label = 0
            try turbine_spacing_label = Int(turbine_spacing[row]); catch; turbine_spacing_label = turbine_spacing[row]; end
            ylabel("$(turbine_spacing_label)\$D\$", rotation=0, fontsize=16)
        end
        axis("square")
        xlim([-22,22])
        ylim([-22,22])
        xticks([])
        yticks([])
        ax.spines["bottom"].set_alpha(0)
        ax.spines["top"].set_alpha(0)
        ax.spines["right"].set_alpha(0)
        ax.spines["left"].set_alpha(0)
    end
end
savefig("../data/initial-layouts/farms_sunflower.pdf")

# square_boundary_length = calc_square_boundary_length(turbine_spacing, nturbines, rotor_diameter)
# println("Area of circular boundary is: ", pi*circle_boundary_radius^2)
# println("Area of square baoundary is: ", square_boundary_length^2)


###########################################################################################
# CREATE WIND ROSE PLOTS
###########################################################################################

create_new_windrose_plot_hornsrev_average_speed.([20,120])

### Use windrose_discretizer.py to generate wind rose plots with multiple wind speeds
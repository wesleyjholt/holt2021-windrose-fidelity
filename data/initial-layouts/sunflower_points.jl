"""
    sunflower_points(n; alpha=1.0)

Generates n points within a circle in a sunflower seed pattern.
The code is based on the example found at:
https://stackoverflow.com/questions/28567166/uniformly-distribute-x-points-inside-a-circle

# Arguments
-`n::Int64`: number of points
-`alpha::Float64`: factor that controls the amount of points that are placed on the boundary (higher number = more points on the boundary)
"""
function sunflower_points(n; alpha=1.0)
    #=
    This function generates n points within a circle in a sunflower seed pattern.
    The code is based on the example found at:
    https://stackoverflow.com/questions/28567166/uniformly-distribute-x-points-inside-a-circle
    =#

    function radius(k, n, b)
        if (k + 1) > n - b
            r = 1.0  # put on the boundary
        else
            r = sqrt((k + 1.0) - 1.0/2.0)/sqrt(n - (b + 1.0)/2.0)   # apply square root
        end
        return r
    end

    x = zeros(n)
    y = zeros(n)
    b = round(alpha*sqrt(n))    # number of boundary points
    phi = (sqrt(5.0) + 1.0)/2   # golden ratio

    for k = 1:n
        r = radius(k, n, b)
        theta = 2.0*pi*(k + 1)/phi^2
        x[k] = r*cos(theta)
        y[k] = r*sin(theta)
    end

    return x, y
end


function get_average_spacing(x, y, n_close_neighbors_per_turbine)

    # get number of points
    n = length(x)
    # initialize variable to hold sum of all minimum spacings
    min_spacing_sum = 0.0
    # loop through each point
    for i = 1:n
        # initialize array to hold minimum spacing values for point i
        min_spacing = fill(Inf, n_close_neighbors_per_turbine)
        # loop through each point again
        for j = 1:n
            # don't do this if it includes finding a point's distance from itself
            if i !== j
                # find distance between points 1 and j
                d = sqrt((x[i] - x[j])^2 + (y[i] - y[j])^2)
                # check if d is smaller than any of the smallest distances found so far for point i
                small_distance = true
                comparing_index = n_close_neighbors_per_turbine
                while small_distance
                    small_distance = false
                    if comparing_index > 0
                        if d < min_spacing[comparing_index]
                            small_distance = true
                            comparing_index -= 1
                        end
                    end
                end
                # if d is one of the smallest distances, place it in the min_spacing array and kick out the largest distance in the array
                if comparing_index < n_close_neighbors_per_turbine
                    insert!(min_spacing, comparing_index+1, d)
                    pop!(min_spacing)
                end
            end
        end
        # add the average minimum spacing for point i to the sum of all minimum spacings
        min_spacing_sum += sum(min_spacing)/n_close_neighbors_per_turbine
    end
    # find the average spacing for the points
    average_spacing = min_spacing_sum/n

    return average_spacing
end


function calc_circle_boundary_radius(desired_spacing, nturbines, rotor_diameter, n_close_neighbors_per_turbine=1)

    # get the turbine coordinates (based on sunflower pattern)
    x,y = sunflower_points(nturbines)
    # find the average spacing between the turbines
    normalized_spacing = get_average_spacing(x, y, n_close_neighbors_per_turbine)
    # find the required boundary diameter to achieve the desired average turbine spacing
    circle_boundary_radius = desired_spacing*rotor_diameter/normalized_spacing

    return circle_boundary_radius
end

function calc_square_boundary_length(desired_spacing, nturbines, rotor_diameter)

    rotor_diameter*desired_spacing*sqrt(nturbines)

end


turbine_spacing = 5
nturbines = 4
rotor_diameter = 126.4
circle_boundary_radius = calc_circle_boundary_radius(turbine_spacing, nturbines, rotor_diameter, 2)

x,y = sunflower_points(nturbines) .* circle_boundary_radius
for i = 1:length(x)
    plt.gcf().gca().add_artist(plt.Circle((x[i],y[i]), rotor_diameter/2, fill=false))
end
plt.gcf().gca().add_artist(plt.Circle((0.0,0.0), circle_boundary_radius, fill=false))
axis("square")
xlim([-circle_boundary_radius*1.3, circle_boundary_radius*1.3])
ylim([-circle_boundary_radius*1.3, circle_boundary_radius*1.3])


square_boundary_length = calc_square_boundary_length(turbine_spacing, nturbines, rotor_diameter)

println("Area of circular boundary is: ", pi*circle_boundary_radius^2)
println("Area of square baoundary is: ", square_boundary_length^2)

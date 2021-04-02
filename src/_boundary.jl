abstract type FarmBoundary end


"""
    CircleBoundary(radius, center)

Container for parameters describing a circular wind farm boundary.

# Arguments
- `radius::Float64`: radius of the circular farm boundary
- `tol::Array{Float64,1}`: center of the farm
"""
struct CircleBoundary{F, AF} <: FarmBoundary
    radius::F
    center::AF
end
CircleBoundary() = CircleBoundary(1000.0, [0.0, 0.0])
CircleBoundary(a::Float64) = CircleBoundary(a, [0.0, 0.0])


"""
    RectangleBoundary(base, height, center)

Container for parameters describing a rectangular wind farm boundary.

# Arguments
- `base::Float64`: base of the rectangular farm boundary
- `height::Float64`: height of the rectangular farm boundary
- `tol::Array{Float64,1}`: center of the farm
"""
struct RectangleBoundary{F, AF} <: FarmBoundary
    base::F
    height::F
    center::AF
    # vertices::AF
    # normals::AF
end
RectangleBoundary() = RectangleBoundary(1000.0, 1000.0, [0.0, 0.0])#, zeros(4,2), zeros(4,2))
RectangleBoundary(b, h) = RectangleBoundary(b, h, [0.0, 0.0])


"""
    ParallelogramBoundary(base, height, angle, center)

Container for parameters describing a parallelogram-shaped wind farm boundary.

# Arguments
- `base::Float64`: base of the parallelogram-shaped farm boundary
- `height::Float64`: height of the parallelogram-shaped farm boundary
- `angle::Float64`: angle of stretch (in degrees)
- `tol::Array{Float64,1}`: center of the farm
"""
struct ParallelogramBoundary{F, AF} <: FarmBoundary
    base::F
    height::F
    angle::F
    center::AF
end
ParallelogramBoundary() = ParallelogramBoundary(1000.0, 1000.0, 10.0, [0.0, 0.0])
ParallelogramBoundary(a, b) = ParallelogramBoundary(a, b, 10.0, [0.0, 0.0])
ParallelogramBoundary(a, b, c) = ParallelogramBoundary(a, b, c, [0.0, 0.0])


"""
    FreeFormBoundary(vertices)

Container for parameters describing a free-form wind farm boundary.

# Arguments
- `vertices::Array{Float64,2}`: corrdinates (x,y) for the vertices of the free-form boundary
"""
struct FreeFormBoundary{AF} <: FarmBoundary
    vertices::AF
end


"""
    get_boundary_params(farm_boundary::CircleBoundary)

Gener
"""
function get_boundary_params(farm_boundary::CircleBoundary)
end


"""
    get_boundary_params(farm_boundary::RectangleBoundary)
"""
function get_boundary_params(farm_boundary::RectangleBoundary)

    base = farm_boundary.base
    height = farm_boundary.height
    center = farm_boundary.center

    vertices = [center[1]-base/2 center[2]-height/2;
                center[1]+base/2 center[2]-height/2;
                center[1]+base/2 center[2]+height/2;
                center[1]-base/2 center[2]+height/2]
    
    normals = boundary_normals_calculator(vertices)

    return vertices, normals
end






"""
    boundary_normals_calculator(boundary_vertices)

Outputs the unit vectors perpendicular to each boundary of a shape, given the Cartesian coordinates for the shape's vertices.

# Arguments
- `boundary_vertices::Array{Float,1}` : n-by-2 array containing all the boundary vertices, counterclockwise
"""
function boundary_normals_calculator(boundary_vertices)
    # get number of vertices in shape
    nvertices = length(boundary_vertices[:, 1])
    # add the first vertex to the end of the array to form a closed loop
    boundary_vertices = [boundary_vertices; boundary_vertices[1,1] boundary_vertices[1,2]]
    # initialize array to hold boundary normals
    boundary_normals = zeros(nvertices, 2)
    # iterate over each boundary
    for i = 1:nvertices
        # create a vector normal to the boundary
        boundary_normals[i, :] = [-(boundary_vertices[i+1,2] - boundary_vertices[i,2]); boundary_vertices[i+1,1] - boundary_vertices[i,1]]
        # normalize the vector
        boundary_normals[i, :] = boundary_normals[i,:]/sqrt(sum(boundary_normals[i,:].^2))
    end

    return boundary_normals
end


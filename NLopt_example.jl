using NLopt
using Snopt

# function myfunc(x::Vector, grad::Vector)
#     if length(grad) > 0
#         grad[1] = 2*(200*x[1]^3 - 200*x[1]*x[2] + x[1] - 1)
#         grad[2] = -200*x[1]^2 + 400*x[2]^3 + x[2]*(202 - 400*x[3]) - 2
#         grad[3] = 200*(x[3] - x[2]^2)
#     end
#     return 100*(x[2] - x[1]^2)^2 + (1 - x[1])^2 + 100(x[3] - x[2]^2)^2 + (1 - x[2])^2
# end

# function myconstraint(x::Vector, grad::Vector, a, b)
#     if length(grad) > 0
#         grad[1] = 3a * (a*x[1] + b)^2
#         grad[2] = -1
#     end
#     (a*x[1] + b)^3 - x[2]
# end

# ---- NLOPT FUNCTIONS ----

function quadfunc_withgrad!(x::Vector, grad::Vector)
    if length(grad) > 0
        grad[1] = 2*(x[1] + 1.0)
        grad[2] = 2*(x[2] - 2.0)
        grad[3] = 2*(x[3] + 3.0)
    end
    f = (x[1] + 1)^2 + (x[2] - 2)^2 + (x[3] + 3)^2
    return f
end

function constraintfunc_onecon_withgrad!(x::Vector, grad::Vector)
    if length(grad) > 0
        grad[1] = -1.0
        grad[2] = 0.0
        grad[3] = 0.0
    end
    return 2.0 - x[1]
end

function constraintfunc_withgrad!(c::Vector, x::Vector, grad::Matrix)
    m = 2 # number of constraints
    n = 3 # number of design variables
    if length(grad) > 0
        for i = 1:n
            for j = 1:m
                grad[i,j] = 0.0
            end
        end
        grad[1,1] = -1.0
        grad[2,2] = 1.0
        grad[3,2] = -1.0
    end
    # c[1] = 2.0 - x[1]
    # c[2] = x[2] - x[3]
    c[:] = [2.0 - x[1], x[2] - x[3]]
end

# ---- SNOPT FUNCTIONS ----

function quadfunc(x)
    return (x[1] + 1.0)^2 + (x[2] - 2.0)^2 + (x[3] + 3.0)^2
end

function dquadfunc(x)
    grad = zeros(3)
    grad[1] = 2*(x[1] + 1.0)
    grad[2] = 2*(x[2] - 2.0)
    grad[3] = 2*(x[3] + 3.0)
    return grad
end

function constraintfunc(x)
    c = zeros(2)
    c[1] = 2.0 - x[1]
    c[2] = x[2] - x[3]
    return c
end

function dconstraintfunc(x)
    dcdx = zeros(2,3)
    dcdx[1,1] = -1.0
    dcdx[2,2] = 1.0
    dcdx[2,3] = -1.0
    return dcdx
end

function obj_func(x)
    f = quadfunc(x)
    c = constraintfunc(x)
    dfdx = dquadfunc(x)
    dcdx = dconstraintfunc(x)
    fail = false
    return f, c, dfdx, dcdx, fail
end

function obj_func_nocon(x)
    f = quadfunc(x)
    dfdx = dquadfunc(x)
    fail = false
    return f, [], dfdx, [], fail
end

# opt = Opt(:GN_ISRES, 3)
# opt = Opt(:LD_SLSQP, 3)
opt = Opt(:GN_CRS2_LM, 3)
lb = [-10., -10., -10]
ub = [10., 10., 10.]
opt.lower_bounds = lb
opt.upper_bounds = ub
opt.xtol_rel = 1e-6
x = [9.2, 1.1, 0.5]
options = Dict{String, Any}()
options["Derivative option"] = 1
options["Verify level"] = 3

opt.min_objective = quadfunc_withgrad!
# inequality_constraint!(opt, (x,g) -> myconstraint(x,g,2,0), 1e-8)
# inequality_constraint!(opt, (x,g) -> myconstraint(x,g,-1,1), 1e-8)
# inequality_constraint!(opt, constraintfunc_withgrad!, fill(1e-8, 2))
# inequality_constraint!(opt, constraintfunc_onecon_withgrad!, 1e-8)

(fopt_nlopt, xopt_nlopt, ret) = optimize(opt, x)
xopt_snopt, fopt_snopt, info = snopt(obj_func, x, lb, ub, options)
println("NLopt fopt: ", fopt_nlopt)
println("Snopt fopt: ", fopt_snopt)
println("NLopt xopt: ", xopt_nlopt)
println("Snopt fopt: ", xopt_snopt)


numevals = opt.numevals # the number of function evaluations
println("got $fopt_nlopt at $xopt_nlopt after $numevals iterations (returned $ret)")
layout_number = Base.parse(Int, ENV["layout_number"])
ndirs = Base.parse(Int, ENV["ndirs"])

println("layout number is: ", layout_number)
println(typeof(layout_number), "\n")
println("number of directions: ", ndirs)
println(typeof(ndirs), "\n")

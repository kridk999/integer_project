using JuMP
using GLPK

mo = Model(GLPK.Optimizer) #Setting up the model

#Solved as a binary problem
@variable(mo,y[1:6], Bin)
@variable(mo,x[1:6,1:6], Bin)


n = length(y)                       #Defining the number of variables

v = (400, 450, 520, 330, 400, 350, 250, 300, 280, 310, 340, 290, 275, 180, 310) # Size of the containers
a = (290, 240, 210, 300, 175, 190, 95, 190, 210, 80, 115, 95, 260, 140, 210) # Volume of the containers

# Defining the objective function
#∑yᵢ for i = 1:n
@objective(mo, Min, sum( y[i] for i=1:n))  #Setting up the objective function

# Defining the constraints

#∑aᵢ*xᵢⱼ for i = 1:n, i ≠ j + aⱼ*yⱼ  ≦ vⱼ*yⱼ, ∀j
@constraint(mo, [j = 1:n], sum(a[i]*x[i,j]  for i = 1:n if i!=j) + a[j]*y[j]<= v[j]*y[j])
#∑aᵢ*xᵢⱼ for j = 1:n, i ≠ j + yᵢ  = 1, ∀i
@constraint(mo, [i = 1:n], sum(x[i,j] for j = 1:n if i!=j) + y[i]  == 1)

optimize!(mo)                   #Solving the model

println("Objective value = ", objective_value(mo)) ## Printing the solution

println("y = ", value.(y)) # Remember a dot for printing a vector

println("X = ")
for i in 1:n
    for j in 1:n
        print(value(x[i,j]) , " ")
    end
    println()
end

println("Solver status: ", termination_status(mo))
println("Solution status: ", primal_status(mo))
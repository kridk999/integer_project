using JuMP
using GLPK

function solve_production_plan()
    # --- 1. Parameters ---
    # Number of weeks
    n = 10

    # Weekly demand
    d = [150, 180, 200, 120, 250, 160, 170, 190, 140, 220]

    # Weekly production cost per item
    p = [20, 22, 21, 23, 20, 24, 22, 21, 25, 23]

    # Weekly inventory holding cost per item
    h = 3

    # Maximum total backlogged items across all weeks
    Qb = 100

    # Maximum number of machine restarts
    Qs = 3 # Example value

    # Big-M value: A safe upper bound for weekly production
    M = sum(d)

    # --- 2. Model Initialization ---
    model = Model(GLPK.Optimizer)

    # --- 3. Decision Variables ---
    @variable(model, x[1:n] >= 0)      # Quantity produced in week w
    @variable(model, i[1:n] >= 0)      # Inventory at the end of week w
    @variable(model, b[1:n] >= 0)      # Backlog at the end of week w
    @variable(model, y[1:n], Bin)    # 1 if machine is on in week w, 0 otherwise
    @variable(model, s[1:n], Bin)    # 1 if a restart occurs in week w, 0 otherwise
    @variable(model, x_max >= 0)     # Max production in any week with production
    @variable(model, x_min >= 0)     # Min production in any week with production
   
    # --- 4. Objective Function ---
    # Minimize the difference between the largest and smallest weekly production
    @objective(model, Min, x_max - x_min)

    # --- 5. Constraints ---
    # Define x_max and x_min
    @constraint(model, max_prod_def[w in 1:n], x_max >= x[w])
    @constraint(model, min_prod_def[w in 1:n], x_min <= x[w] + M * (1 - y[w]))

    # Inventory/Backlog balance constraint for the first week (w=1)
    @constraint(model, balance_1, i[1] - b[1] == x[1] - d[1])

    # Inventory/Backlog balance constraints for subsequent weeks (w > 1)
    @constraint(model, balance_rest[w in 2:n], i[w] - b[w] == i[w-1] - b[w-1] + x[w] - d[w])

    # Production can only occur if the machine is on (Big-M constraint)
    @constraint(model, production_activation[w in 1:n], x[w] <= M * y[w])

    # Force machine to be off if there is no production
    @constraint(model, machine_off_if_no_production[w in 1:n], y[w] <= M * x[w])


    # --- New Constraints for Restarts ---
    # A restart in week 1 occurs if the machine is on
    @constraint(model, restart_week_1, s[1] >= y[1])

    # A restart in week w > 1 occurs if machine was off in w-1 and is on in w
    @constraint(model, restart_subsequent_weeks[w in 2:n], s[w] >= y[w] - y[w-1])

    # Limit the total number of restarts
    @constraint(model, total_restarts, sum(s) <= Qs)
    # --- End of New Constraints ---

    # Total backlog limit
    @constraint(model, total_backlog, sum(b) <= Qb)

    # No backlog allowed at the end of the planning horizon
    @constraint(model, final_backlog, b[n] == 0)

    # --- 6. Solve the Model ---
    optimize!(model)

    # --- 7. Display Results ---
    if termination_status(model) == OPTIMAL
        println("Optimal solution found!")
        println("---------------------------------")
        println("Production Variation (Max - Min) = ", objective_value(model))
        println("Max Production: ", value(x_max))
        println("Min Production: ", value(x_min))
        println("---------------------------------")
        println("Week\tDemand\tProduce\tMachineOn\tInventory\tBacklog")
        for w in 1:n
            prod_val = round(Int, value(x[w]))
            inv_val = round(Int, value(i[w]))
            back_val = round(Int, value(b[w]))
            y_val = round(Int, value(y[w]))
            println("$w\t$(d[w])\t$prod_val\t$y_val\t\t$inv_val\t\t$back_val")
        end
        println("---------------------------------")
        println("Total Restarts: ", sum(value.(s)))
        println("Total Backlog: ", sum(value.(b)))
    else
        println("No optimal solution found. Status: ", termination_status(model))
    end
end

# Run the function
solve_production_plan()
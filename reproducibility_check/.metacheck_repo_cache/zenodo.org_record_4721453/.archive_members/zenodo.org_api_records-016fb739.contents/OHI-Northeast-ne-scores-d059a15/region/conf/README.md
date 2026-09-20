**File structure**

config.R: define model parameters, weighting files, etc.
functions.R: functions used to calculate goal/subgoal status and trend scores
goals.csv: list of goals and corresponding weights
flower_plot.R: function to create the OHI flower plot
pressures_matrix.csv: Weights for each pressure layer and goal
pressure_categories: Defines the pressure category for each pressure layer
resilience_matrix.csv: Indicates which resilience layers affect which goals
resilience_categories: Defines the resilience category for each resilience layer
scenario_data_years.csv: Links the scenario year to the corresponding year of the data for each data layer
ne_pressure_function.R: an updated version of the `CalculatePressuresAll()` function from `ohicore`
ne_resilience_function.R: an updated version of the `CalculateResilienceAll()` function from `ohicore`

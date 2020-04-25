using Test, Dates, Julianda

include("../TraderData.jl")

Julianda.getPrice(foo,["EUR_USD"])
# Checks for the right response depending on the time
#TODO: redo pricing tests

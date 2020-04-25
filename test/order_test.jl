using Test, Julianda

include("../TraderData.jl")

@test Julianda.marketOrder(foo, "GBP_USD", 100)

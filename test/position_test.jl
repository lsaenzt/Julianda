using Test, Julianda

include("../TraderData.jl")

bar = Julianda.listPositions(foo)
@test length(bar) != 0

bar = Julianda.listOpenPositions(foo)
@test bar != nothing

bar = Julianda.getPosition(foo, "GBP_USD")

@test bar.instrument == "GBP_USD"

@test Julianda.closePosition(foo, "GBP_USD", 50)

@test Julianda.closePositionFull(foo, "GBP_USD")

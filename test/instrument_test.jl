using Test, Dates, Julianda

include("../TraderData.jl")
inst = "GBP_USD" # Instrument to test with

bar = Julianda.getCandles(foo, inst, 1)
@test length(bar.candles) == 1
dt = DateTime(2019,7,1)
bar = Julianda.getCandles(foo, inst, dt, dt)
@test length(bar.candles) == 500
bar = Julianda.getCandles(foo, inst, dt, 1)
@test length(bar.candles) == 1
bar = Julianda.getCandles(foo, inst, 1, dt)
@test length(bar.candles) == 1

bar = Julianda.getOrderBook(foo, inst, dt)
@test length(bar.buckets) == 1745

bar = Julianda.getPositionBook(foo, inst, dt)
@test length(bar.buckets) == 598

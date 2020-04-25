# ------------------------------------------------------------------------------------
# CandleStick Structs and JSON3 types
# ------------------------------------------------------------------------------------

# All structs defined here except latestCandles are common with those in Instrument.jl
mutable struct candlestickdata
    o   #open
    h   #high
    l   #low
    c   #close

    candlestickdata() = new()
end

mutable struct candlestick
    complete::Bool
    volume
    time
    bid::candlestickdata
    ask::candlestickdata
    mid::candlestickdata

    candlestick() = new()
end

mutable struct candles
    instrument::String
    granularity::String
    candles::Vector{candlestick}

    candles() = new()
end


struct latestCandles
    latestCandles::Vector{candles}
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{candlestickdata}) = JSON3.Mutable()
JSON3.StructType(::Type{candlestick}) = JSON3.Mutable()
JSON3.StructType(::Type{candles}) = JSON3.Mutable()
JSON3.StructType(::Type{latestCandles}) = JSON3.Struct()

# ------------------------------------------------------------------------------------
# Price Structs and JSON3 types
# ------------------------------------------------------------------------------------

"Ask / Bid pricing data"
mutable struct priceBucket
    price # Price of the ask / bid
    liquidity # liquidity of the ask / bid

    priceBucket() = new()
end

"Pricing data of an instrument"
mutable struct price
    type # Type
    instrument
    time # Time of the price update
    bids::Vector{priceBucket} # Bid information
    asks::Vector{priceBucket} # Ask information
    closeoutBid # Closeout bid price
    closeoutAsk # Closeout Ask price
    tradeable # Can you trade this instrument

    price() = new()
end

"Needed for JSON parsing"
mutable struct priceTopLayer
    prices::Vector{price} # Prices
    time

    priceTopLayer() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{priceBucket}) = JSON3.Mutable()
JSON3.StructType(::Type{price}) = JSON3.Mutable()
JSON3.excludes(::Type{price})=(:status,:quoteHomeConversionFactors,:unitsAvailable) #Ignore deprecated fields
JSON3.StructType(::Type{priceTopLayer}) = JSON3.Mutable()

# ------------------------------------------------------------------------------------
# Coercion functions
# ------------------------------------------------------------------------------------


"Coerce pricing data into proper types"
function coercePrice(price::price)
    # Coerce Asks
    for ask in price.asks
        ask.price = parse(Float32, ask.price)
    end
    # Coerce Bids
    for bid in price.bids
        bid.price = parse(Float32, bid.price)
    end
    price.time = DateTime(first(price.time, 23), Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ"))
    price.closeoutBid = parse(Float32, price.closeoutBid)
    price.closeoutAsk = parse(Float32, price.closeoutAsk)

    return price
end



# Conversions to proper Julia types
function coerceCandleStick(config, candle::candlestick)

    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")

    candle.time = DateTime(candle.time, RFC)
    isdefined(candle, :bid) && (candle.bid = coerceCandleStickData(candle.bid))
    isdefined(candle, :ask) && (candle.ask = coerceCandleStickData(candle.ask))
    isdefined(candle, :mid) && (candle.mid = coerceCandleStickData(candle.mid))

    return candle
end

function coerceCandleStickData(candleData::candlestickdata)

    candleData.o = parse(Float32, candleData.o)
    candleData.h = parse(Float32, candleData.h)
    candleData.l = parse(Float32, candleData.l)
    candleData.c = parse(Float32, candleData.c)

    return candleData
end

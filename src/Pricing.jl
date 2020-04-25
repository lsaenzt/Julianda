
export getPrice, streamPrice, getLatestCandles

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/pricing Endpoint
# ------------------------------------------------------------------------------------

"""
    function getPrice(config, instruments)

Get the most recent price update of an instrument

# Arguments
    - 'config::config': a valid struct with user configuracion data
    - 'instruments::Vector{String}': a vector of valid pairs (e.g. ["EUR_USD","EUR_JPY"])

#Example

    getPrice(userconfig, ["EUR_USD","EUR_JPY"])

"""
function getPrice(config, instruments::Vector{String})

    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/",config.account,"/pricing?instruments=", join(instruments,",")),
                ["Authorization" => string("Bearer ", config.token)])

    data = JSON3.read(r.body, priceTopLayer)

    for priceData in data.prices
        coercePrice(priceData)
    end

    return data.prices #Does not return 'since' datetime=#
end


"Exception thrown when the market is closed on the weekend"
struct ClosedMarketException <: Exception end

"Get the most recent price update of an instrument"
function checkMarket()
    dt = Dates.now()
    if Dates.dayofweek(dt) >= 5
        if Dates.dayofweek(dt) == 5 & Dates.hour(dt) < 4
        elseif Dates.dayofweek(dt) == 7 & Dates.hour(dt) >= 5
        else
            throw(ClosedMarketException())
        end
    end
end
# ------------------------------------------------------------------------------------
# /accounts/{accountID}/pricing/stream Endpoint
# ------------------------------------------------------------------------------------
"""
    function streamprice(f, config , instruments)

Returns a stream of price objects and apply a function to each one of them

# Arguments
    - 'f::Function': a function to apply to each price struct object. Streamprice accepts do block format
    - 'config::config': a valid struct with user configuracion data
    - 'instruments::Vector{String}': a vector of valid pairs (e.g. ["EUR_USD","EUR_JPY"])

#Example

    streamprice(userconfig, ["EUR_JPY"]) do price
        println(price)
    end
"""
function streamPrice(f::Function, config, instruments::Vector{String})

@async HTTP.open("GET",
        string("https://", config.streamingHostname, "/v3/accounts/",config.account,"/pricing/stream?instruments=", join(instruments,",")),
        ["Authorization" => string("Bearer ", config.token)]) do io
            for line in eachline(io)
                p = JSON3.read(line, price)
                p.type != "HEARTBEAT" && f(p) #Cleans HEARTBEAT ticks -> only prices are sent to f
            end
        end
end

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/candles/latest Endpoint
# ------------------------------------------------------------------------------------

"""
    function getLatestCandles(config, candleSpecs; kwargs...,)


Information includes: time, granularity, open, high, low, close, volume and a complete indicator

# Arguments
- 'config::config': a valid struct with user configuration data
- 'candleSpecs::Vector': A vector of tuples indicating the specifications for candle to retrieve.
    The tuple must have the instrument, granularity and price component in this order

Valid granularities: ["S5","S10","S15","S30","M1","M2","M4","M5","M10","M15","M30","H1","H2","H3","H4","H6","H8","H12","D","W","M"]
Valid prices: "A" for ask, "B" for bid, "M" for medium or a combination of them

# Keyword Arguments
- 'units::Number'
- 'smooth::Bool'
- 'dailyaligment::Int'
- 'alignmentTimezone::String'
- 'weeklyAlignment::String'

# Example

    getLatestCandles(userconfig, [("EUR_USD","M1","AB"),(("EUR_CHF","M5","M"))])
    getLatestCandles(sim02, [("EUR_USD","M1","AB"),(("EUR_CHF","M5","M"))])

"""

function getLatestCandles(config, candleSpecs::Vector, kwargs...,)

    cspec = join([join(i,":") for i in candleSpecs ],",")

    r = HTTP.get(string("https://",config.hostname,"/v3/accounts/",config.account,"/candles/latest"),
        ["Authorization" => string("Bearer ", config.token)];
        query = push!(Dict(),"candleSpecifications"=> cspec, kwargs...,),)

    temp = JSON3.read(r.body, latestCandles)

    #type coersions
    for latestc in temp.latestCandles
        for c in latestc.candles
        c = coerceCandleStick(config, c)
        end
    end

    return temp

end


# ------------------------------------------------------------------------------------
# /accounts/{accountID}/instrument/{instrument}/candle Endpoint
# ------------------------------------------------------------------------------------

"""
This endopoint is alsmost identical to /instruments/{instrument}/candles -> Not a priority

Only difference is the 'units' keyword argument

"""
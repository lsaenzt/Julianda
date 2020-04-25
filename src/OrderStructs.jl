# ------------------------------------------------------------------------------------
# Client Extensions Structs and JSON3 types
# ------------------------------------------------------------------------------------

# clientExtension request structs
struct extensions
    id::String
    tag::String
    comment::String
end

# For JSON parsing
struct clientExtensions
    clientExtensions::extensions
end


# Declaring JSON3 struct types
JSON3.StructType(::Type{clientExtensions}) = JSON3.Struct()
JSON3.StructType(::Type{extensions}) = JSON3.Struct()

# ------------------------------------------------------------------------------------
# Order Structs and JSON3 types
# ------------------------------------------------------------------------------------

mutable struct takeProfit
    price::Real
    timeInForce::String
    gtdTime::String
    # clientExtensions::extensions -> TODO

    takeProfit() = new()
end

mutable struct stopLoss
    price::Real
    distance::Real 
    timeInForce::String
    gtdTime::String
    # clientExtensions::extensions -> TODO

    stopLoss() = new()
end

mutable struct trailingStopLoss
    distance::Real
    timeInForce::String
    gtdTime::String
    # clientExtensions::extensions -> TODO

    trailingStopLoss() = new()
end

"Detailed OrderRequest struct from Oanda"
mutable struct orderRequest
    clientExtensions::clientExtensions 
    distance # for orders on fill
    gtdTime
    instrument # instrument of the order
    positionFill # Type of position fill on the order
    price # Price the order is placed at
    priceBound 
    stopLossOnFill::stopLoss # Stop loss settings for an order
    takeProfitOnFill::takeProfit
    timeInForce # Type of time in force
    tradeClientExtensions::clientExtensions
    tradeID::String
    trailingStopLossOnFill::trailingStopLoss
    triggerCondition # Trigger condition of the order
    type # Type of order
    units # Number of units (negative for a short, positive for a long)

    orderRequest() = new()
end

"For JSON parsing"
struct order2send
    order::orderRequest
end


mutable struct orders
    orders::Array{Dict{String,Any},1}
    lastTransactionID::String

    orders() = new()
end

mutable struct singleOrder
    order::Dict{String,Any}
    lastTransactionID::String

    singleOrder() = new()
end

# Declaring JSON3 struct types

JSON3.StructType(::Type{takeProfit}) = JSON3.Mutable()
JSON3.omitempties(::Type{takeProfit})=(:price,:timeInForce,:gtdTime)

JSON3.StructType(::Type{stopLoss}) = JSON3.Mutable()
JSON3.omitempties(::Type{stopLoss})=(:price,:distance,:timeInForce,:gtdTime)

JSON3.StructType(::Type{trailingStopLoss}) = JSON3.Mutable()
JSON3.omitempties(::Type{trailingStopLoss})=(:price,:timeInForce,:gtdTime)

JSON3.StructType(::Type{orderRequest}) = JSON3.Mutable()
JSON3.omitempties(::Type{orderRequest})=(:price, :units, :distance, :priceBound,:triggerCondition,:gtdTime,
                                         :takeProfitOnFill,:stopLossOnFill,:trailingStopLossOnFill,
                                         :clientExtensions,:tradeID, :tradeClientExtensions)

JSON3.StructType(::Type{order2send}) = JSON3.Struct()

JSON3.StructType(::Type{orders}) = JSON3.Mutable()
JSON3.StructType(::Type{singleOrder}) = JSON3.Mutable()

#------------------------------------------------------------------------------------
# Coercion functions
#------------------------------------------------------------------------------------

"Recursive coersion of order Dictionaries to proper Julia types"
function coerceOrderDict(oDict::Dict{String,Any}) #Also used in getOrder endpoints

    valueFields = ["price","priceBound", "distance","trailingStopValue","initialMaketPrice"]

    timeFields = ["createTime","gtdTime","filledTime","cancelledTime"]

    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")

    for (key, value) in oDict
        if eltype(value) == Pair{String,Any}
            oDict[key] = coerceOrderDict(oDict[key]) #Recursion for Dictionaries inside a transaction field
        elseif eltype(value) == Any #'asks' & 'bids' in 'fullPrice' have an array of liquidity, prices
            oDict[key] = collect(coerceOrderDict.(oDict[key]))
        elseif key in valueFields
            oDict[key] = parse(Float32, value)
        elseif key == "units" && value != "ALL"
            oDict[key] = parse(Float32, value)
        elseif key in timeFields
            oDict[key] = DateTime(first(value, 23), RFC)
        end
    end

    return oDict
end

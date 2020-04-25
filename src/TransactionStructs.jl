#------------------------------------------------------------------------------------
# Transaction Structs and JSON3 types
#------------------------------------------------------------------------------------

mutable struct transactionPages
    from
    to
    pageSize
    type::Vector{String}
    count
    pages::Vector{String}
    lastTransactionID

    transactionPages() = new()
end

mutable struct transaction
    transaction::Dict{String,Any}
    lastTransactionID

    transaction() = new()
end

mutable struct transactions
    transactions::Array{Dict{String,Any},1}
    lastTransactionID

    transactions() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{transactionPages}) = JSON3.Mutable()
JSON3.StructType(::Type{transaction}) = JSON3.Mutable()
JSON3.StructType(::Type{transactions}) = JSON3.Mutable()



#------------------------------------------------------------------------------------
# Coercion functions
#------------------------------------------------------------------------------------

# Conversions to proper Julia types
function coerceTransactionPages(tpages::transactionPages)

    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")

    tpages.from = DateTime(first(tpages.from, 23), RFC) #DateTime has milliseconds precision. Can only use 23 characters...
    tpages.to = DateTime(first(tpages.to, 23), RFC)
    tpages.lastTransactionID = parse(Int, tpages.lastTransactionID)

    return tpages
end

"Recursive coersion of transaction Dictionaries to proper Julia types"
function coerceTransactionDict(tDict::Dict{String,Any}) #Also used in getTransactions endpoints

    valueFields = [
        "price","priceBound","fullVWAP","distance","closeoutBid","closeoutAsk","marginRate","initialMarginRequired","requestedUnits","liquidity",
        "gainQuoteHomeConversionFactor","lossQuoteHomeConversionFactor","AccountBalance","amount","financing","pl","commission",
        "guaranteedExecutionFee","halfSpreadCost","dividend","realizedPL","bidLiquidityUsed","askLiquidityUsed",]

    timeFields = ["timestamp", "time", "gtdTime"]
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")

    for (key, value) in tDict
        if eltype(value) == Pair{String,Any}
            tDict[key] = coerceTransactionDict(tDict[key]) #Recursion for Dictionaries inside a transaction field
        elseif eltype(value) == Any #'asks' & 'bids' in 'fullPrice' have an array of liquidity, prices
            tDict[key] = collect(coerceTransactionDict.(tDict[key]))
        elseif key in valueFields
            tDict[key] = parse(Float32, value)
        elseif key == "units" && value != "ALL"
            tDict[key] = parse(Float32, value)
        elseif key in timeFields
            tDict[key] = DateTime(first(value, 23), RFC)
        end
    end

    return tDict
end

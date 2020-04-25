# ------------------------------------------------------------------------------------
# Trade Structs and JSON3 types
# ------------------------------------------------------------------------------------

"Detailed Trade struct from Oanda"
mutable struct trade
    averageClosePrice # The average closing price of the Trad
    clientExtensions # The client extensions of the Trade
    closingTransactionIDs # The IDs of the Transactions that have closed portions of this Trade
    closeTime # The date/time when the Trade was fully closed
    currentUnits # Current units of the trade (- is short + is long)
    dividend # The dividend paid for this Trade
    financing # The financing paid / collected for this trade
    id # The id of the trade
    initialUnits # Initial opening units of the trade (- is short + is long)
    initialMarginRequired # The margin required at the time the Trade was created
    instrument # Instrument of the trade
    marginUsed # Margin currently used by the Trade
    openTime # The time the trade was opened
    price # The price the trade is set at
    realizedPL # The profit / loss of the trade that has been incurred
    state # current state of the trade
    takeProfitOrder # Full representation of the Trade’s Take Profit Order
    stopLossOrder # Full representation of the Trade’s Stop Loss Order
    trailingStopLossOrder # Full representation of the Trade’s Trailing Stop Loss Order
    unrealizedPL # The profit / loss of the trade that hasnt been incurred
    #= Better alternative that requires complete implementation of Order.jl
    takeProfitOrder::takeProfitOrder
    stopLossOrder::stopLossOrder
    trailingStopLossOrder::trailingStopLossOrder
    =#
    trade() = new()
end


mutable struct trades
    trades::Vector{trade}
    lastTransactionID

    trades() = new()
end

mutable struct singleTrade
    trade::trade
    lastTransactionID

    singleTrade() = new()
end


# orders endpoint response struct
mutable struct tradeOrdersResponse
    takeProfitOrderCancelTransaction::Dict{String,Any}
    takeProfitOrderTransaction::Dict{String,Any}
    takeProfitOrderFillTransaction::Dict{String,Any}
    takeProfitOrderCreatedCancelTransaction::Dict{String,Any}
    stopLossOrderCancelTransaction::Dict{String,Any}
    stopLossOrderTransaction::Dict{String,Any}
    stopLossOrderCreatedCancelTransaction::Dict{String,Any}
    trailingStopLossOrderCancelTransaction::Dict{String,Any}
    trailingStopLossOrderTransaction::Dict{String,Any}
    relatedTransactionIDs::Vector{String}
    lastTransactionID

    tradeOrdersResponse() = new()
end
# Declaring JSON3 struct types
JSON3.StructType(::Type{trades}) = JSON3.Mutable()
JSON3.StructType(::Type{trade}) = JSON3.Mutable()
JSON3.StructType(::Type{singleTrade}) = JSON3.Mutable()
JSON3.StructType(::Type{tradeOrdersResponse}) = JSON3.Mutable()


# ------------------------------------------------------------------------------------
# Close trade response Structs and JSON3 types
# ------------------------------------------------------------------------------------

# close trade endpoint response struct
mutable struct closeUnitsResp
    orderCreateTransaction::Dict{String,Any}
    orderFillTransaction::Dict{String,Any}
    orderCancelTransaction::Dict{String,Any}
    relatedTransactionIDs::Vector{String}
    lastTransactionID

    closeUnitsResp() = new()
end

# close trade endpoint request struct
struct closeUnits
    units::String

    closeUnits(x::String) = new(x)

    function closeUnits(x::Real)
        str = string(x)
        new(str)
    end

end


# Declaring JSON3 struct types
JSON3.StructType(::Type{closeUnits}) = JSON3.Struct()
JSON3.StructType(::Type{closeUnitsResp}) = JSON3.Mutable()


# ------------------------------------------------------------------------------------
# Send cancel orders Structs and JSON3 types
# ------------------------------------------------------------------------------------

# Definition of cancelTradeOrders structs
mutable struct nullTradeOrders
    takeProfit
    stopLoss
    trailingStopLoss


    nullTradeOrders()=new()
end

# Declaring JSON3 struct types and setting fields to ignore in JSON3.write if # undef
JSON3.StructType(::Type{nullTradeOrders}) = JSON3.Mutable()
JSON3.omitempties(::Type{nullTradeOrders})=(:takeProfit,:stopLoss,:trailingStopLoss)


#------------------------------------------------------------------------------------
# Coercion functions
#------------------------------------------------------------------------------------

"Coerce a given 'trade' into its proper types (Used internally)"
function coerceTrade(trade::trade)
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")

    isdefined(trade,:averageClosePrice) && (trade.averageClosePrice = parse(Float32,trade.averageClosePrice))
    isdefined(trade,:closeTime) && (trade.closeTime = DateTime(first(trade.closeTime,23),RFC))
    trade.currentUnits = parse(Float32, trade.currentUnits)
    trade.initialUnits = parse(Float32, trade.initialUnits)
    trade.initialMarginRequired = parse(Float32,trade.initialMarginRequired)
    trade.financing = parse(Float32, trade.financing)
    # ID is left as a string, makes more sense to me for usage
    isdefined(trade,:marginUsed) && (trade.marginUsed = parse(Float32, trade.marginUsed))
    trade.openTime = DateTime(first(trade.openTime,23),RFC)
    trade.price = parse(Float32, trade.price)
    trade.realizedPL = parse(Float32, trade.realizedPL)
    isdefined(trade,:unrealizedPL) && (trade.unrealizedPL = parse(Float32, trade.unrealizedPL))
    #= Requires complete implementation of Order.jl
    isdefined(trade,:takeProfitOrder) && (trade.takeProfitOrder = coerceTakeProfitOrder(trade.takeProfitOrder))
    isdefined(trade,:stopLossOrder) && (trade.stopLossOrder = coerceStopLossOrder(trade.stopLossOrder))
    isdefined(trade,:trailingStopLossOrder) && (trade.trailingStopLossOrder = coerceTrailingStopLossOrder(trade.trailingStopLossOrder))
    =#
    return trade
end

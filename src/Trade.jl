
export getTrades, getOpenTrades, getTrade, closeTrade, setTradeOrders

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/trades Endpoint
# /accounts/{accountID}/openTrades Endpoint
# ------------------------------------------------------------------------------------
"""
    getTrades(config::config, instrument::String, state::String="OPEN", count::Int=50; kwargs...)

Return an array of trade struct

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'state::String": the state to filter the requested Trades by (OPEN, CLOSED, CLOSE_WHEN_TRADEABLE, ALL)
- 'count::Int': max number of trades to return

# Keyword Arguments
- 'instrument::String": a valid instrument (e.g. "EUR_USD")
- 'ids::String' List of trades to retrieve as ID values separated by commas
- 'beforeID::String' The maximum trade ID to return

# Examples

    getTrades(userConfig,"CLOSED";instrument="EUR_USD")

"""
function getTrades(config, state::String="ALL", count::Int=50; kwargs...)

    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/", config.account, "/trades"),
        ["Authorization" => string("Bearer ", config.token)];
        query = push!(Dict(), "state" => state, "count" => count, kwargs...))

    temp = JSON3.read(r.body,trades)
    # type coersions
    for t in temp.trades
        t = coerceTrade(t)
    end
    temp.trades # Not returning lastTransactionID. That info belongs to Transaction.jl
end

"""
    getOpenTrades(config::config)

Return an array of trade struct

# Arguments
- 'config::config': a valid struct with user configuracion data

# Examples

    getOpenTrades(userconfig)

"""
function getOpenTrades(config)

    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/", config.account, "/openTrades"),
        ["Authorization" => string("Bearer ", config.token)])

    temp = JSON3.read(r.body,trades)

    # type coersions
    for t in temp.trades
        t = coerceTrade(t)
    end
    return temp.trades # Not returning lastTransactionID. That info belongs to Transaction.jl
end

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/trades/{tradeSpecifier} Endpoint
# ------------------------------------------------------------------------------------

"""
   getTrade(config::config, tradeID::String)

Return a specific trade

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'id::string': a valid trade ID

# Examples

    getTrades(userconfig,"66")

"""
function getTrade(config, tradeID::String)

    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/", config.account,"/trades/",tradeID),
        ["Authorization" => string("Bearer ", config.token)])

    temp = JSON3.read(r.body,singleTrade)

    return coerceTrade(temp.trade) # Not returning lastTransactionID. That info belongs to Transaction.jl
end

# ------------------------------------------------------------------------------------
# //accounts/{accountID}/trades/{tradeSpecifier}/close Endpoint
# ------------------------------------------------------------------------------------

"""
    closeTrade(config::config, tradeID::String, units::Union{Real,String}="ALL")

Return an array of trade struct

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'tradeID::string': a valid trade ID
- 'units::Union{Number,String}': how much of the Trade to close in units or "ALL"

# Examples

    closeTrade(userconfig,"66","ALL")

"""
function closeTrade(config, tradeID::String, units::Union{Real,String}="ALL")

    r = HTTP.put(string("https://", config.hostname, "/v3/accounts/", config.account,"/trades/",tradeID,"/close"),
        ["Authorization" => string("Bearer ", config.token),"Content-Type" => "application/json"], JSON3.write(closeUnits(units)))

    return JSON3.read(r.body,closeUnitsResp)

end

# ------------------------------------------------------------------------------------
# //accounts/{accountID}/trades/{tradeSpecifier}/clientExtensions Endpoint
# ------------------------------------------------------------------------------------

"""
    clientExtensions(config::config, tradeID::String; clientID::String="", tag::String="", comment::String="")

Lets add user information to a specific Trade

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'tradeID::string': a valid trade ID
- clientID, tag and comment: strings with the user information

# Example

    clientExtensions(userconfig,"66", clientID="007",tag="foo")

"""
function clientExtensions(config, tradeID::String; clientID::String="", tag::String="", comment::String="")

    data = clientExtensions(extensions(clientID, tag, comment))

    r = HTTP.put(string("https://", config.hostname, "/v3/accounts/", config.account,"/trades/",tradeID,"/clientExtensions"),
        ["Authorization" => string("Bearer ", config.token),"Content-Type" => "application/json"], JSON3.write(data))

    return JSON3.read(r.body, clientExtensionsResp)

end

# ------------------------------------------------------------------------------------
# //accounts/{accountID}/trades/{tradeSpecifier}/orders Endpoint
# ------------------------------------------------------------------------------------

"""
    function setTradeOrders(config::config, tradeID::String; [TP::NamedTuple, SL::NamedTuple, tSL::NamedTuple ])

Create or modify the linked orders for a specific trade

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'tradeID::string': a valid trade ID

# Additional Arguments
- 'TP::NamedTuple' Take Profit parameters
- 'SL::NamedTuple': Stop Loss parameters
- 'tSL::NamedTuple': Trailing Stop Loss parameters

At least one type of order parameters must be provided

# Valid order parameters
- 'price = :Real' :price to create o modify for the specific order. Valir for Stop Loss and Take Profit
- 'distance = :Real' :price distance to create o modify for the specific order. Valir for Stop Loss and Trailing Stip Loss
- 'TIF= String': time in force for the order. Valid options are: GTC, GTD, GFD, FOK, IOC. Defaults to GTC
- 'gtdTime = DateTime': time for GTD (Good unTill Date)

Price and distance are incompatible. Only one can be set for a given order.

# Example

    setTradeOrders(userconfig, "34"; TP=(price=109.5,), SL=(distance=10,TIF="FOK")) # Do not forget the comma for 1 element NamedTuples

"""
function setTradeOrders(config, tradeID::String; TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple())

    data = tradeOrders()

    if !isempty(TP)
        TPdetails = takeProfit()
        haskey(TP, :price) && (TPdetails.price = TP.price)
        haskey(TP, :timeInForce) && (TPdetails.timeInForce = TP.timeInForce)
        haskey(TP, :gtdTime) && (TPdetails.price = Dates.format(TP.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        data.takeProfit = TPdetails
    end

    if !isempty(SL)
        SLdetails = stopLoss()
        haskey(SL, :price) && (SLdetails.price = SL.price)
        haskey(SL, :distance) && (SLdetails.distance = SL.distance)
        haskey(SL, :timeInForce) && (SLdetails.timeInForce = SL.timeInForce)
        haskey(SL, :gtdTime) && (SLdetails.price = Dates.format(SL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        data.stopLoss = SLdetails
    end

    if !isempty(tSL)
        tSLdetails = trailingStopLoss()
        haskey(tSL, :distance) && (tSLdetails.distance = tSL.distance)
        haskey(tSL, :timeInForce) && (tSLdetails.timeInForce = tSL.timeInForce)
        haskey(tSL, :gtdTime) && (tSLdetails.price = Dates.format(tSL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        data.trailingStopLoss = tSLdetails
    end


    r = HTTP.put(string("https://", config.hostname, "/v3/accounts/", config.account,"/trades/",tradeID,"/orders"),
        ["Authorization" => string("Bearer ", config.token),"Content-Type" => "application/json"], JSON3.write(data))

    return JSON3.read(r.body,tradeOrdersResponse)

end

"""
    function cancelTradeOrders(config::config, tradeID::String, orders2cancel::Vector{String})

Cancel linked orders of a specific trade

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'tradeID::string': a valid trade ID
- 'orders2cancel::Vector{String}': list of orders to cancel.

order2cancel valid fields are "TP" for Take Profit, "SL" for Stop Loss and "tSL" for Trailing Stop Loss

# Example

    cancelTradeOrders(userconfig, "34", ["SL", "TP"])

end
"""
function cancelTradeOrders(config, tradeID::String, orders2cancel::Vector{String})

    data=nullTradeOrders()

    in("TP",orders2cancel) && (data.takeProfit=missing)
    in("SL",orders2cancel) && (data.stopLoss=missing)
    in("tSL",orders2cancel) && (data.trailingStopLoss=missing)

    r = HTTP.put(string("https://", config.hostname, "/v3/accounts/", config.account,"/trades/",tradeID,"/orders"),
    ["Authorization" => string("Bearer ", config.token),"Content-Type" => "application/json"], JSON3.write(data))

    return JSON3.read(r.body,tradeOrdersResponse)
end
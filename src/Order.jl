
export marketOrder, limitOrder, stopOrder, marketIfTouchedOrder, replaceOrder, cancelOrder, getPendingOrders

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders POST Endpoint
# ------------------------------------------------------------------------------------

# market order -----------------------------------------------------------------------
"""
    marketOrder(config, instrument, units;[TIF, positionFill, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])

Places a market order

#Arguments
- 'config::config': a valid struct with user configuration data
- 'instrument::String': a valid instrument (e.g. "EUR_USD")
- 'units::String': units to buy (positive value) or sell (negative value)

# Keyword Arguments
- 'TIF::String' : timeinForce value ("GTC","GTD","GFD","FOK","IOC")
- 'positionFill::String' : how positions are modified when the order is filled ("OPEN_ONLY", "REDUCE_FIRST", "REDUCE_ONLY","DEFAULT"). Defaults to "DEFAULT"
- 'priceBound::String': worst price for filling
- 'TP', 'SL', 'tSL' : a NamedTuple with order-on-fill details. Valid values are 'price::Real', 'distance::Real', 'timeInForce::String' and 'gtdTime::String' 
- 'clientExt'(not implemented)
- 'tradeExt' (not implemented)

#Examples

   marketOrder(userData,"EUR_JPY",100)
   marketOrder(userData,"EUR_CHF",100,SL=(distance=0.1,),TP=(price=1.12,),tSL=(distance=0.3,)) #Do not forget the comma for single value NamedTuple
"""
function marketOrder(config::config, instrument::String, units::Real;
                     TIF::String = "FOK", positionFill::String = "DEFAULT", priceBound::Union{Nothing,String}=nothing,
                     TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
                     clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple())
  
    o = orderRequest()
    
    o.type = "MARKET"
    o.instrument = instrument
    o.units = units
    o.timeInForce = TIF
    o.positionFill = positionFill
    o.priceBound = priceBound

    if !isempty(TP)
        TPdetails = takeProfit()
        haskey(TP, :price) && (TPdetails.price = TP.price)
        haskey(TP, :timeInForce) && (TPdetails.timeInForce = TP.timeInForce)
        haskey(TP, :gtdTime) && (TPdetails.price = Dates.format(TP.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.takeProfitOnFill = TPdetails
    end

    if !isempty(SL)
        SLdetails = stopLoss()
        haskey(SL, :price) && (SLdetails.price = SL.price)
        haskey(SL, :distance) && (SLdetails.distance = SL.distance)
        haskey(SL, :timeInForce) && (SLdetails.timeInForce = SL.timeInForce)
        haskey(SL, :gtdTime) && (SLdetails.price = Dates.format(SL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.stopLossOnFill = SLdetails
    end

    if !isempty(tSL)
        tSLdetails = trailingStopLoss()
        haskey(tSL, :distance) && (tSLdetails.distance = tSL.distance)
        haskey(tSL, :timeInForce) && (tSLdetails.timeInForce = tSL.timeInForce)
        haskey(tSL, :gtdTime) && (tSLdetails.price = Dates.format(tSL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.trailingStopLossOnFill = tSLdetails
    end

    # TODO: Client Extensions

    data = order2send(o)

    r = HTTP.post(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders",),
        ["Authorization" => string("Bearer ", config.token), "Content-Type" => "application/json", ],
        JSON3.write(data),)

    return JSON3.read(r.body,Dict{String,Any}) 
end


# Other type of orders -----------------------------------------------------------------------
"""
 nonMarketOrder(config, type, instrument, units, price;[TIF, gtdTime, positionFill, trigge, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])

 generic order function for limit, stop and marketIfTouchedOrders
"""

function nonMarketOrder(config::config, type::String, instrument::String, units::Real, price::Real;
    TIF::String = "GTC", gtdTime::Union{Nothing,String}=nothing, positionFill::String = "DEFAULT", trigger::String="DEFAULT",priceBound::Union{Nothing,String}=nothing,
    TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
    clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple())

    o = orderRequest()

    o.type = type
    o.instrument = instrument
    o.units = units
    o.price = price
    o.timeInForce = TIF
    o.priceBound = priceBound
    !isnothing(gtdTime) && (o.gtdTime = Dates.format(gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))
    o.positionFill = positionFill
    o.triggerCondition = trigger

    if !isempty(TP)
        TPdetails = takeProfit()
        haskey(TP, :price) && (TPdetails.price = TP.price)
        haskey(TP, :timeInForce) && (TPdetails.timeInForce = TP.timeInForce)
        haskey(TP, :gtdTime) && (TPdetails.price = Dates.format(TP.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.takeProfitOnFill = TPdetails
    end

    if !isempty(SL)
        SLdetails = stopLoss()
        haskey(SL, :price) && (SLdetails.price = SL.price)
        haskey(SL, :distance) && (SLdetails.distance = SL.distance)
        haskey(SL, :timeInForce) && (SLdetails.timeInForce = SL.timeInForce)
        haskey(SL, :gtdTime) && (SLdetails.price = Dates.format(SL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.stopLossOnFill = SLdetails
    end

    if !isempty(tSL)
        tSLdetails = trailingStopLoss()
        haskey(tSL, :distance) && (tSLdetails.distance = tSL.distance)
        haskey(tSL, :timeInForce) && (tSLdetails.timeInForce = tSL.timeInForce)
        haskey(tSL, :gtdTime) && (tSLdetails.price = Dates.format(tSL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.trailingStopLossOnFill = tSLdetails
    end

    # TODO: Client Extensions

    data = order2send(o)

    r = HTTP.post(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders",),
    ["Authorization" => string("Bearer ", config.token), "Content-Type" => "application/json", ],
    JSON3.write(data),)

    return JSON3.read(r.body,Dict{String,Any})
end

# limit order -----------------------------------------------------------------------
"""

    limitOrder(config, instrument, units, price;[TIF, positionFill, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])
 
Places a limit Order

#Arguments
- 'config::config': a valid struct with user configuration data
- 'instrument::String': a valid instrument (e.g. "EUR_USD")
- 'units::String': units to buy (positive value) or sell (negative value)
- 'price::Real'

# Keyword Arguments
- 'TIF::String' : timeinForce value ("GTC","GTD","GFD","FOK","IOC")
- 'positionFill::String' : how positions are modified when the order is filled ("OPEN_ONLY", "REDUCE_FIRST", "REDUCE_ONLY","DEFAULT"). Defaults to "DEFAULT"
- 'priceBound::String': worst price for filling
- 'TP', 'SL', 'tSL' : a NamedTuple with order-on-fill details. Valid values are 'price::Real', 'distance::Real', 'timeInForce::String' and 'gtdTime::String' 
- 'clientExt'(not implemented)
- 'tradeExt' (not implemented)

#Examples

   limitOrder(userData,"EUR_USD",100, 1.10)
   limitOrder(userData,"EUR_JPY",100,117,SL=(distance=1,),TP=(price=12,),tSL=(distance=3,)) #Do not forget the comma for single value NamedTuple
"""
limitOrder(config::config, instrument::String, units::Real, price::Real;
                    TIF::String = "GTC", gtdTime::Union{Nothing,String}=nothing, positionFill::String = "DEFAULT", trigger::String="DEFAULT",
                    TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
                    clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple()) = 
        nonMarketOrder(config, "LIMIT", instrument, units, price; 
                   TIF=TIF, gtdTime=gtdTime, positionFill=positionFill, trigger=trigger, 
                   TP=TP, SL=SL ,tSL=tSL, clientExt=clientExt, tradeExt=tradeExt)
    
 # stop order -----------------------------------------------------------------------
"""
    stopOrder(config, instrument, units, price;[TIF, positionFill, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])

Places a stop Order

#Arguments
- 'config::config': a valid struct with user configuration data
- 'instrument::String': a valid instrument (e.g. "EUR_USD")
- 'units::String': units to buy (positive value) or sell (negative value)
- 'price::Real'

# Keyword Arguments
- 'TIF::String' : timeinForce value ("GTC","GTD","GFD","FOK","IOC")
- 'positionFill::String' : how positions are modified when the order is filled ("OPEN_ONLY", "REDUCE_FIRST", "REDUCE_ONLY","DEFAULT"). Defaults to "DEFAULT"
- 'priceBound::String': worst price for filling
- 'TP', 'SL', 'tSL' : a NamedTuple with order-on-fill details. Valid values are 'price::Real', 'distance::Real', 'timeInForce::String' and 'gtdTime::String' 
- 'clientExt'(not implemented)
- 'tradeExt' (not implemented)

#Examples

  stopOrder(userData,"EUR_USD",100, 1.10)
  stopOrder(userData,"EUR_JPY",100,117,SL=(distance=1,),TP=(price=12,),tSL=(distance=3,)) #Do not forget the comma for single value NamedTuple
"""
stopOrder(config::config, instrument::String, units::Real, price::Real;
                   TIF::String = "GTC", gtdTime::Union{Nothing,String}=nothing, positionFill::String = "DEFAULT", trigger::String="DEFAULT", priceBound::Union{Nothing,String}=nothing,
                   TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
                   clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple()) = 
       nonMarketOrder(config, "STOP", instrument, units, price; 
                  TIF=TIF, gtdTime=gtdTime, positionFill=positionFill, trigger=trigger, priceBound = priceBound,
                  TP=TP, SL=SL ,tSL=tSL, clientExt=clientExt, tradeExt=tradeExt)


# market if touched order -----------------------------------------------------------------------
"""
marketIfTouchedOrder(config, instrument, units, price;[TIF, positionFill, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])

Places a market-if-touched Order

#Arguments
- 'config::config': a valid struct with user configuration data
- 'instrument::String': a valid instrument (e.g. "EUR_USD")
- 'units::String': units to buy (positive value) or sell (negative value)
- 'price::Real'

# Keyword Arguments
- 'TIF::String' : timeinForce value ("GTC","GTD","GFD","FOK","IOC")
- 'positionFill::String' : how positions are modified when the order is filled ("OPEN_ONLY", "REDUCE_FIRST", "REDUCE_ONLY","DEFAULT"). Defaults to "DEFAULT"
- 'priceBound::String': worst price for filling
- 'TP', 'SL', 'tSL' : a NamedTuple with order-on-fill details. Valid values are 'price::Real', 'distance::Real', 'timeInForce::String' and 'gtdTime::String' 
- 'clientExt'(not implemented)
- 'tradeExt' (not implemented)

#Examples

  marketifTouchedOrder(userData,"EUR_uSD",100, 1.10)
  marketifTouchedOrder(userData,"EUR_JPY",100,117,SL=(distance=1,),TP=(price=12,),tSL=(distance=3,)) #Do not forget the comma for single value NamedTuple
"""
marketIfTouchedOrder(config::config, instrument::String, units::Real, price::Real;
                   TIF::String = "GTC", gtdTime::Union{Nothing,String}=nothing, positionFill::String = "DEFAULT", trigger::String="DEFAULT", priceBound::Union{Nothing,String}=nothing,
                   TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
                   clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple()) = 
       nonMarketOrder(config, "MARKET_IF_TOUCHED", instrument, units, price; 
                  TIF=TIF, gtdTime=gtdTime, positionFill=positionFill, trigger=trigger, priceBound = priceBound,
                  TP=TP, SL=SL ,tSL=tSL, clientExt=clientExt, tradeExt=tradeExt)
    
                  
 # related Orders (Stop loss, take profit, trailing stop loss) -----------------------------------------------------------------------
 
 """
     relatedOrder(config, tradeID, type, detail)
 
 Places a stop loss, take profit or trailing stop loss to an open trade (not order)

#Arguments
- 'config::config': a valid struct with user configuration data
- 'tradeID::Union{Int,String}': a valid open trade ID (e.g. "123")
- 'type::String' : type of the order "STOP_LOSS", "TAKE_PROFIT" or "TRAILING_STOP_LOSS"
- 'details::NamedTuple': a NamedTuple with order-on-fill details. Valid values are 'price::Real', 'distance::Real', 'timeInForce::String' and 'gtdTime::String' 

 #Examples
 
    relatedOrder(config, "156", "STOP_LOSS", details=(distance=0.1,)) #Do not forget the comma for single value NamedTuple 
 """
function relatedOrder(config, tradeID::Union{Int,String}, type::String, details::NamedTuple=NamedTuple() )

    o = orderRequest()
    
    o.type = type
    o.tradeID = string(tradeID)
    o.timeInForce = "GTC"
  
    haskey(details, :price) && (o.price = details.price)
    haskey(details, :distance) && (o.distance = details.distance)
    haskey(details, :timeInForce) && (o.timeInForce = details.timeInForce)
    haskey(details, :gtdTime) && (o.price = Dates.format(details.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

    data = order2send(o)

    r = HTTP.post(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders",),
        ["Authorization" => string("Bearer ", config.token), "Content-Type" => "application/json", ],
        JSON3.write(data),)

    return JSON3.read(r.body,Dict{String,Any})  
end

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders GET Endpoint
# ------------------------------------------------------------------------------------

"""
getOrders(config, count::Int=50; kwargs...)
getOrders(config, IDlist::Vector; kwargs...)

#Arguments
- 'config::config': a valid struct with user configuration data
- 'count::Int': number of orders to return
- 'IDlist::Vector{String}' : a vector of valid order IDs

#Keyword Arguments
- 'state::String: a string with values "PENDING", "FILLED", "TRIGGERED", "CANCELLED" or "ALL". Defaults to "PENDING"
- 'instrument::String'
- 'beforeID::String': last ID to retrieve

#Examples
    getOrders(userData,5)
    getOrders(userData,25, state="FILLED", instrument="EUR_USD")
    getOrders(userData,["123","234","345"])
"""
function getOrders(config, count::Int=50; kwargs...)

    r = HTTP.get(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders",),
                        ["Authorization" => string("Bearer ", config.token)];
                        query = push!(Dict(),"count"=>count, kwargs...,),)

    temp = JSON3.read(r.body, orders)

    for dict in temp.orders
        dict = coerceOrderDict(dict)
    end

    return temp.orders
end

function getOrders(config, IDlist::Vector; kwargs...)
    
    r = HTTP.get(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders",),
                        ["Authorization" => string("Bearer ", config.token)];
                        query = push!(Dict(),"ids" => join(IDlist,","), kwargs...,),)    

    temp = JSON3.read(r.body, orders)

    for dict in temp.orders
        dict = coerceOrderDict(dict)
    end

    return temp.orders
end

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/pendingOrders GET Endpoint
# ------------------------------------------------------------------------------------
"""
getPendingOrders(config)

#Examples
    getPendingOrders(userData)  
"""
function getPendingOrders(config)
    
    r = HTTP.get(string("https://",config.hostname,"/v3/accounts/",config.account,"/pendingOrders",),
                        ["Authorization" => string("Bearer ", config.token)],)    
    
    temp = JSON3.read(r.body, orders)

    for dict in temp.orders
        dict = coerceOrderDict(dict)
    end

    return temp.orders
end

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders/{orderSpecifier} GET Endpoint
# ------------------------------------------------------------------------------------

"""
getOrder(config, orderID)

#Arguments
- 'config::config': a valid struct with user configuration data
- 'orderID::Union{String,Int}' : avalid order IDs

#Examples
    getOrder(userdata,"100")  
"""
function getOrder(config, orderID::Union{String,Int})
    
    r = HTTP.get(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders/",orderID),
                        ["Authorization" => string("Bearer ", config.token)],)    
    
    temp = JSON3.read(r.body, singleOrder)       
    temp.order = coerceOrderDict(temp.order)

    return temp.order
end

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders/{orderSpecifier} PUT Endpoint
# ------------------------------------------------------------------------------------

"""
 replaceOrder(config, ID, instrument, units;[TIF, positionFill, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])

#Examples

   replaceOrder(userData,165,"LIMIT","EUR_JPY",100)
   replaceOrder(userData,170,"EUR_CHF",100,SL=(distance=0.1,),TP=(price=1.12,),tSL=(distance=0.3,))
"""
function replaceOrder(config::config, orderID::Union{Int,String},type::String, instrument::String, units::Real, price::Real;
    TIF::String = "GTC", gtdTime::Union{Nothing,String}=nothing, positionFill::String = "DEFAULT", trigger::String="DEFAULT",priceBound::Union{Nothing,String}=nothing,
    TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
    clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple())

    o = orderRequest()

    o.type = type
    o.instrument = instrument
    o.units = units
    o.price = price
    o.timeInForce = TIF
    o.priceBound = priceBound
    !isnothing(gtdTime) && (o.gtdTime = Dates.format(gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))
    o.positionFill = positionFill
    o.triggerCondition = trigger

    if !isempty(TP)
        TPdetails = takeProfit()
        haskey(TP, :price) && (TPdetails.price = TP.price)
        haskey(TP, :timeInForce) && (TPdetails.timeInForce = TP.timeInForce)
        haskey(TP, :gtdTime) && (TPdetails.price = Dates.format(TP.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.takeProfitOnFill = TPdetails
    end

    if !isempty(SL)
        SLdetails = stopLoss()
        haskey(SL, :price) && (SLdetails.price = SL.price)
        haskey(SL, :distance) && (SLdetails.distance = SL.distance)
        haskey(SL, :timeInForce) && (SLdetails.timeInForce = SL.timeInForce)
        haskey(SL, :gtdTime) && (SLdetails.price = Dates.format(SL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.stopLossOnFill = SLdetails
    end

    if !isempty(tSL)
        tSLdetails = trailingStopLoss()
        haskey(tSL, :distance) && (tSLdetails.distance = tSL.distance)
        haskey(tSL, :timeInForce) && (tSLdetails.timeInForce = tSL.timeInForce)
        haskey(tSL, :gtdTime) && (tSLdetails.price = Dates.format(tSL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.trailingStopLossOnFill = tSLdetails
    end

    # TODO: Client Extensions

    data = order2send(o)

    r = HTTP.put(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders/",orderID),
    ["Authorization" => string("Bearer ", config.token), "Content-Type" => "application/json", ],
    JSON3.write(data),)

    return JSON3.read(r.body,Dict{String,Any})
end

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders/{orderSpecifier}/cancel PUT Endpoint
# ------------------------------------------------------------------------------------

"""
cancelOrder(config, ID::Union{String,Int})

#Arguments
- 'config::config': a valid struct with user configuration data
- 'orderID::Union{String,Int}' : avalid order IDs

#Examples
    cancelOrder(userdata,"100")  
"""
function cancelOrder(config, ID::Union{String,Int})
    
    r = HTTP.put(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders/",ID,"/cancel"),
                        ["Authorization" => string("Bearer ", config.token)],)    
           
    temp = JSON3.read(r.body,Dict{String,Any})

    temp["orderCancelTransaction"]["time"] = DateTime(first(temp["orderCancelTransaction"]["time"], 23),Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ"))
    
    temp
end

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders/{orderSpecifier}/clientExtension PUT Endpoint
# ------------------------------------------------------------------------------------

"""
    orderClientExtensions(config::config, tradeID::String; clientID::String="", tag::String="", comment::String="")

Lets add user information to a specific Trade

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'tradeID::string': a valid trade ID
- clientID, tag and comment: strings with the user information

# Example

    orderClientExtensions(userconfig,"66", clientID="007",tag="foo")
"""
function orderClientExtensions(config, orderID::Union{Int,String}; clientID::String="", tag::String="", comment::String="")

    data = clientExtensions(extensions(clientID, tag, comment))

    r = HTTP.put(string("https://", config.hostname, "/v3/accounts/", config.account,"/orders/",orderID,"/clientExtensions"),
        ["Authorization" => string("Bearer ", config.token),"Content-Type" => "application/json"], JSON3.write(data))   

    return JSON3.read(r.body, Dict{String,Any})
end
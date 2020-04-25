export listPositions, listOpenPositions, getPosition, closePosition

"""
   listPositions(config)

Returns a list of current positions
"""
function listPositions(config)
    r = HTTP.get(        string("https://",config.hostname,"/v3/accounts/",config.account,"/positions",),
        ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => config.datetime,])

    data = JSON3.read(r.body, positionTopLayer)
    data = data.positions

    temp = Vector{position}()
    for pos in data
        pos = coercePos(pos)
        push!(temp, pos)
    end

    return temp
end

"""
    listOpenPositions(config)

Returns a list of current positions that have an open trade
"""
function listOpenPositions(config)
    r = HTTP.get(        string("https://",config.hostname,"/v3/accounts/",config.account,"/openPositions",),
        ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => config.datetime,],)

    data = JSON3.read(r.body, positionTopLayer)
    data = data.positions

    temp = Vector{position}()
    for pos in data
        pos = coercePos(pos)
        push!(temp, pos)
    end

    return temp
end

"""
    getPosition(config, instrument)

Returns position data for a specified instrument
"""
function getPosition(config, instrument)
    r = HTTP.get(string("https://",config.hostname,"/v3/accounts/",config.account,"/positions/",instrument,),
        ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => config.datetime,],)

    data = JSON3.read(r.body, positionTopLayerSingle)

    data = coercePos(data.position)

    return data
end

"""
    closePositionFull(config, instrument, long=true)

Closes a position completely
"""
function closePositionFull(config, instrument, long=true)
    data = ""
    if long
        data = "{\"longUnits\": \"ALL\"}"
    else
        data = "{\"shortUnits\": \"ALL\"}"
    end

    r = HTTP.put(string("https://",config.hosame,"/v3/accounts/",config.account,"/positions/",instrument,"/close"),
        ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => config.datetime,"Content-Type" => "application/json",],
        data,)

    return true
end

"""
    closePosition(config, instrument, LongUnits=NONE, ShortUnits=NONE)

Closes a positions units based on input
"""
function closePosition(config, instrument, longUnits="NONE", shortUnits="NONE")

    r = HTTP.put(string("https://",config.hostname,"/v3/accounts/",config.account,"/positions/",instrument,"/close"),
        ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => config.datetime,"Content-Type" => "application/json",],
        string("{\"longUnits\": \"", longUnits,"\",\n\"shortUnits\": \"", shortUnits,"\"}"),)

    return true
end
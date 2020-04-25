
export listAccounts, getAccountSummary

"""
    listAccounts(config::config)

Returns a list of all account IDs and tags authorized for the given Token
"""
function listAccounts(config)
    r = HTTP.get(string("https://", config.hostname, "/v3/accounts"),
        ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => config.datetime,],)

    data = JSON3.read(r.body, accountsList)

    return data.accounts

end

"""
    getAccount(config::config)

Returns an Oanda account struct when given a valid config
"""
function getAccount(config)

    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/", config.account),
        ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => config.datetime,],)

    temp = JSON3.read(r.body, topLayer)

    temp = temp.account
    # Type Coersions
    temp = coerceAccountSummary(temp)

    return temp
end

"""
    getAccountSummary(config::config)

Similar to getAccount but doesnt return the order & trade & positions lists, however
it still returns a full account struct, just with these fields left undefined
"""
function getAccountSummary(config)

    r = HTTP.get( string("https://",config.hostname,"/v3/accounts/",config.account,"/summary",),
        ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => config.datetime,],)

    temp = JSON3.read(r.body, topLayer)

    temp = temp.account

    # Type Coersions
    temp = coerceAccountSummary(temp)

    return temp
end

"""
    getAccountInstruments(config::config, inst=nothing)

Returns a list of tradeable instruments details for the account

# Arguments
- inst: Can be left blank to return all tradeable instruments, or as a string csv of instruments to return their details
"""
function getAccountInstruments(config, inst = nothing)

    request = string("https://",config.hostname,"/v3/accounts/",config.account,"/instruments",)

    !isnothing(inst) && (request = string(request, "?instruments=", inst))

    r = HTTP.get(request,
        ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => config.datetime,],)

    data = JSON3.read(r.body, instrumentTopLayer)
    data = data.instruments
    instruments = Vector{instrumentDetail}()

    for inst in data
        inst = coerceInstrumentDetail(inst)
        push!(instruments, inst)
    end

    return instruments
end

"""
    setAccountConfig(config::config, alias::String, marginRate::String)

Set client configurable configuration settings

# Arguments
- alias: The account alias
- marginRate: The desired decimal margin rate formatted as a string
"""
function setAccountConfig(config, alias::String, marginRate::String)

    r = HTTP.request("PATCH", string("https://",config.hostname,"/v3/accounts/",config.account,"/configuration",),
        ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => config.datetime,"Content-Type" => "application/json",],
        JSON3.write(accountConfig(alias, marginRate)),)

    return true
end
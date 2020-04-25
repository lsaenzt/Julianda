"""
The account struct given by Oanda

# Fields
- NAV: The Net Asset Value of an account
- alias: User defined alias if one exists
- balance: Current Account Balance
- createdByUserID: The User ID of the account creator
- createdTime: The time the account was created
- currency: The primary currency of the account
- hedgingEnabled: If the account is allowed to hedge
- id: The account ID
- lastTransactionID: The last transaction ID
- marginAvailable: The margin still available on the account
- marginCloseoutMarginUsed: The closeout margin used
- marginCloseoutNAV: Margins closeout NAV
- marginCloseoutPercent: Margin closeout percent
- marginCloseoutPositionValue: Margin closeout position value
- marginCloseoutUnrealizedPL: Margin closeout unrealised profit/loss
- marginRate: The margin rate
- marginUsed: Amount of margin used
- openPositionCount: Number of open positions
- openTradeCount: Number of open trades
- orders: Orders of the account
- pendingOrderCount: Number of pending orders
- pl: The profit or loss over the lifetime of the account
- positionValue: Value of an accounts open positions
- positions: Positions of the account
- resettablePL: The resetable profit/loss since last reset
- trades: Trades of the account
- unrealizedPL: The unrealised profit/loss of the account
- withdrawalLimit: The withdrawal limit of the account
"""
mutable struct account
    NAV # The Net Asset Value of an account
    alias # User defined alias if one exists
    balance # Current Account Balance
    createdByUserID # The User ID of the account creator
    createdTime # The time the account was created
    currency # The primary currency of the account
    hedgingEnabled # If the account is allowed to hedge
    id # The account ID
    lastTransactionID # The last transaction ID
    marginAvailable # The margin still available on the account
    marginCloseoutMarginUsed # The closeout margin used
    marginCloseoutNAV # Margins closeout NAV
    marginCloseoutPercent # Margin closeout percent
    marginCloseoutPositionValue # Margin closeout position value
    marginCloseoutUnrealizedPL # Margin closeout unrealised profit/loss
    marginRate # The margin rate
    marginUsed # Amount of margin used
    openPositionCount # Number of open positions
    openTradeCount # Number of open trades
    orders::Array{Dict{String,Any},1} # Orders of the account
    pendingOrderCount # Number of pending orders
    pl # The profit or loss over the lifetime of the account
    positionValue # Value of an accounts open positions
    positions::Array{Dict{String,Any},1} # Positions of the account
    resettablePL # The resetable profit/loss since last reset
    trades::Array{Dict{String,Any},1}
     # Trades of the account
    unrealizedPL # The unrealised profit/loss of the account
    withdrawalLimit # The withdrawal limit of the account

    account() = new()
end

"Nessecary for automatic JSON parsing, not for regular use"
mutable struct topLayer
    account::account

    topLayer() = new()
end

"The ID and tag of each account"
mutable struct accountListed
    id # Account id
    tags # Account Tags

    accountListed() = new()
end

"The list of accounts returned by Oanda"
mutable struct accountsList
    accounts::Vector{accountListed} # Array of accounts

    accountsList() = new()
end

"""
Tradeable Instrument data

# Fields
- displayName: Instrument name
- displayPrecision: Decimal precision of the instrument
- marginRate: Margin rate on the instrument
- maximumOrderUnits: Max units that can be ordered
- maximumPositionSize: max position size of the instrument
- maximumTrailingStopDistance: max trailing stop distance
- minimumTrailingStopDistance: min trailing stop distance
- name: Request usable instrument name
- pipLocation: current pip location
- tradeUnitsPrecision: Decimal precision of trade units
- type: Type of instrument
"""
mutable struct instrumentDetail
    displayName # Instrument name
    displayPrecision # Decimal precision of the instrument
    marginRate # Margin rate on the instrument
    maximumOrderUnits # Max units that can be ordered
    maximumPositionSize # max position size of the instrument
    maximumTrailingStopDistance # max trailing stop distance
    #minimumPositionSize # min position size of the instrument
    minimumTrailingStopDistance # min trailing stop distance
    name # Request usable instrument name
    pipLocation # current pip location
    tradeUnitsPrecision # Decimal precision of trade units
    type # Type of instrument

    instrumentDetail() = new()
end

"Nessecary for automatic JSON parsing, not for regular use"
mutable struct instrumentTopLayer
    instruments::Vector{instrumentDetail} # Tradable instruments

    instrumentTopLayer() = new()
end

"For configuring Accounts"
struct accountConfig
    alias::String
    marginRate::String
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{account}) = JSON3.Mutable()
JSON3.StructType(::Type{topLayer}) = JSON3.Mutable()
JSON3.StructType(::Type{accountsList}) = JSON3.Mutable()
JSON3.StructType(::Type{accountListed}) = JSON3.Mutable()
JSON3.StructType(::Type{instrumentDetail}) = JSON3.Mutable()
JSON3.StructType(::Type{instrumentTopLayer}) = JSON3.Mutable()
JSON3.StructType(::Type{accountConfig}) = JSON3.Struct()

# ------------------------------------------------------------------------------------
# Coercion functions
# ------------------------------------------------------------------------------------

"Coerce a given Account Summary into its proper types (Used for getAccount Method)"
function coerceAccountSummary(acc::account)
    acc.NAV = parse(Float32, acc.NAV)
    acc.balance = parse(Float32, acc.balance)
    acc.marginAvailable = parse(Float32, acc.marginAvailable)
    acc.marginCloseoutMarginUsed = parse(Float32, acc.marginCloseoutMarginUsed)
    acc.marginCloseoutNAV = parse(Float32, acc.marginCloseoutNAV)
    acc.marginCloseoutPercent = parse(Float32, acc.marginCloseoutPercent)
    acc.marginCloseoutPositionValue = parse(
        Float32,
        acc.marginCloseoutPositionValue,
    )
    acc.marginCloseoutUnrealizedPL = parse(
        Float32,
        acc.marginCloseoutUnrealizedPL,
    )
    acc.marginRate = parse(Float32, acc.marginRate)
    acc.marginUsed = parse(Float32, acc.marginUsed)
    #acc.openPositionCount = parse(Int32, acc.openPositionCount)
    #acc.openTradeCount = parse(Int32, acc.openTradeCount)
    #acc.pendingOrderCount = parse(Int32, acc.pendingOrderCount)
    acc.pl = parse(Float32, acc.pl)
    acc.positionValue = parse(Float32, acc.positionValue)
    acc.resettablePL = parse(Float32, acc.resettablePL)
    acc.unrealizedPL = parse(Float32, acc.unrealizedPL)
    acc.withdrawalLimit = parse(Float32, acc.withdrawalLimit)

    return acc
end


"Coerce a given instrument detail into its proper types"
function coerceInstrumentDetail(inst::instrumentDetail)
    inst.marginRate = parse(Float32, inst.marginRate)
    inst.maximumOrderUnits = parse(Float64, inst.maximumOrderUnits)
    inst.maximumPositionSize = parse(Float32, inst.maximumPositionSize)
    inst.maximumTrailingStopDistance = parse(
        Float32,
        inst.maximumTrailingStopDistance,
    )
    inst.minimumTrailingStopDistance = parse(
        Float32,
        inst.minimumTrailingStopDistance,
    )

    return inst
end

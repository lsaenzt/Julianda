module Oanda

using JSON3, HTTP, Dates, CodecZlib

# User token and operating account
include("../User.jl")

# Structs for storing key data and coercion functions
include("AccountStructs.jl") #Account and instrument Structs
include("OrderStructs.jl") #Order and Client Extensions Structs
include("TradeStructs.jl") #Trade Structs
include("PriceStructs.jl") #Price and CandleStick Structs
include("PositionStructs.jl") #Position Structs
include("BookStructs.jl") #OrdeBook and PositionBook Structs
include("TransactionStructs.jl") #Transaction Structs

# Functions for interacting with each one of the endpoints
include("Account.jl")
include("Order.jl")
include("Trade.jl")
include("Position.jl")
include("Instrument.jl")
include("Transaction.jl")
include("Pricing.jl")

end
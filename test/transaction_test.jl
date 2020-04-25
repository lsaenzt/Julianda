using Test, Julianda

include("../TraderData.jl")

bar = Julianda.getTransactionPages(foo)
@test bar.pageSize == 100

bar = Julianda.getTransaction(foo, 1)
@test bar["type"] == "CREATE"

bar = Julianda.getTransactions(foo, 1, 1)
@test bars[1]["type"] == "CREATE"
bar = Julianda.getTransactions(foo, 1)
@test bars[1]["type"] == "CLIENT_CONFIGURE"

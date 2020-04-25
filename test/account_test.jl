using Test, Julianda

include("../TraderData.jl")

@test length(Julianda.listAccounts(foo)) != 0

bar = Julianda.listAccounts(foo)
foo2 = Julianda.changeAccount(foo, bar[1].id)
@test foo2 == foo
@test Julianda.saveConfig("../config_test", foo)

@test typeof(Julianda.getAccount(foo)) == Julianda
@test typeof(Julianda.getAccountSummary(foo)) == Julianda
@test length(Julianda.getAccountInstruments(foo)) != 0
@test Julianda.setAccountConfig(foo, "Testing", "0.05")

module RocketTeardownChainTest

using Test

using Rocket

@testset "ChainTeardown" begin

    struct DummyUnsubscribable <: Teardown end
    Rocket.as_teardown(::Type{<:DummyUnsubscribable}) = Rocket.UnsubscribableTeardownLogic()
    Rocket.unsubscribe!(::DummyUnsubscribable) = "unsubscribed"

    @test ChainTeardown(DummyUnsubscribable()) isa Teardown
    @test Rocket.as_teardown(ChainTeardown) === Rocket.UnsubscribableTeardownLogic()
    @test Rocket.unsubscribe!(ChainTeardown(DummyUnsubscribable())) === "unsubscribed"

    @test chain(DummyUnsubscribable()) isa Teardown
    @test Rocket.unsubscribe!(chain(DummyUnsubscribable())) === "unsubscribed"

end

end

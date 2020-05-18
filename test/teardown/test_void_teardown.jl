module RocketTeardownVoidTest

using Test
using Rocket

@testset "VoidTeardown" begin

    @test voidTeardown isa Teardown
    @test Rocket.as_teardown(VoidTeardown) === Rocket.VoidTeardownLogic()
    @test Rocket.unsubscribe!(voidTeardown) === nothing

end

end

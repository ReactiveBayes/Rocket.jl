module RocketTeardownVoidTest

using Test
using Rocket

@testset "VoidTeardown" begin

    @test VoidTeardown() isa Teardown
    @test Rocket.as_teardown(VoidTeardown) === Rocket.VoidTeardownLogic()
    @test Rocket.unsubscribe!(VoidTeardown()) === nothing

end

end

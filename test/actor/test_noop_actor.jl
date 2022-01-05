module RocketNoopActorTest

using Test
using Rocket

@testset "NoopActor" begin

    println("Testing: actor NoopActor")

    @testset begin
        @test noopActor isa Rocket.NoopActor
    end
end

end

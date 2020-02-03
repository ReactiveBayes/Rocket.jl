module RocketLambdaActorTest

using Test
using Rocket

@testset "LambdaActor" begin

    @testset begin
        values = []
        source = from(1:3)
        actor  = LambdaActor{Int}(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        )

        subscribe!(source, actor)

        @test values == [ 1, 2, 3, "completed" ]
    end

    @testset begin
        values = []
        source = from(1:3)
        actor  = lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        )

        subscribe!(source, actor)

        @test values == [ 1, 2, 3, "completed" ]
    end

    @testset begin
        @test lambda(Int; on_next = (d) -> println(d)) isa LambdaActor{Int}
        @test lambda(on_next = (d) -> println(d))      isa Rocket.LambdaActorFactory
    end
end

end

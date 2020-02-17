module RocketLambdaActorTest

using Test
using Rocket

@testset "LambdaActor" begin

    @testset begin
        values = []
        source = from(1:3)

        n = (d) -> push!(values, d)
        e = (e) -> push!(values, e)
        c = ()  -> push!(values, "completed")

        actor  = LambdaActor{Int, typeof(n), typeof(e), typeof(c)}(n, e, c)

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
        n = (d) -> println(d)
        e = (e) -> println(e)
        c = ( ) -> println(0)

        @test lambda(Int; on_next     = n) isa LambdaActor{Int, typeof(n), Nothing, Nothing}
        @test lambda(Int; on_error    = e) isa LambdaActor{Int, Nothing, typeof(e), Nothing}
        @test lambda(Int; on_complete = c) isa LambdaActor{Int, Nothing, Nothing, typeof(c)}
        @test lambda(on_next = (d) -> println(d))      isa Rocket.LambdaActorFactory
    end
end

end

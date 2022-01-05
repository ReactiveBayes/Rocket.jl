module RocketLambdaActorTest

using Test
using Rocket

@testset "LambdaActor" begin

    println("Testing: actor LambdaActor")

    @testset begin
        values = []
        source = from_iterable(1:3)

        n = (d) -> push!(values, d)
        e = (e) -> push!(values, e)
        c = ()  -> push!(values, "completed")

        actor  = LambdaActor{typeof(n), typeof(e), typeof(c)}(n, e, c)

        subscribe!(source, actor)

        @test values == [ 1, 2, 3, "completed" ]
    end

    @testset begin
        values = []
        source = from_iterable(1:3)
        actor  = lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        )

        subscribe!(source, actor)

        @test values == [ 1, 2, 3, "completed" ]
    end

    @testset begin
        values = []
        actor  = lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        )

        next!(actor, 1)

        @test values == [ 1 ]
    end

    @testset begin
        values = []
        actor  = lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        )

        error!(actor, 'e')

        @test values == [ 'e' ]
    end

    @testset begin
        values = []
        actor  = lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        )

        complete!(actor)

        @test values == [ "completed" ]
    end

    @testset begin
        n = (d) -> println(d)
        e = (e) -> println(e)
        c = ( ) -> println(0)

        @test lambda(on_next     = n) isa LambdaActor{typeof(n), Nothing, Nothing}
        @test lambda(on_error    = e) isa LambdaActor{Nothing, typeof(e), Nothing}
        @test lambda(on_complete = c) isa LambdaActor{Nothing, Nothing, typeof(c)}
        @test lambda(on_next     = n, on_error    = e) isa LambdaActor{typeof(n), typeof(e), Nothing  }
        @test lambda(on_error    = e, on_complete = c) isa LambdaActor{Nothing,   typeof(e), typeof(c)}
        @test lambda(on_complete = c, on_next     = n) isa LambdaActor{typeof(n), Nothing,   typeof(c)}
        @test lambda(on_next     = n, on_error    = e, on_complete = c) isa LambdaActor{typeof(n), typeof(e), typeof(c)}
    end
end

end

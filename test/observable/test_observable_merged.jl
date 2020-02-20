module RocketMergedObservableTest

using Test
using Rocket

@testset "MergeObservable" begin

    @testset begin
        observable = merged((of(1), of(2.0)))

        @test subscribable_extract_type(observable) === Union{Int, Float64}

        actor = keep(Union{Int, Float64})

        subscribe!(observable, actor)

        @test actor.values == [ 1, 2.0 ]
    end

    @testset begin
        observable = merged((timer(100, 1), of(2.0), from("Hello"))) |> take(10)
        
        values = []
        actor = sync(lambda(on_next = (d) -> push!(values, d)))
        
        subscribe!(observable, actor)
        
        wait(actor)
        
        @test values == [ 2.0, 'H', 'e', 'l', 'l', 'o', 0, 1, 2, 3 ]
    end

end

end

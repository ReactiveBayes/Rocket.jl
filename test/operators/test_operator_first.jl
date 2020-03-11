module RocketFirstOperatorTest

using Test
using Rocket

@testset "operator: first()" begin

    @testset begin
        source = from(1:42) |> first()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1 ]
    end

    @testset begin
        source = interval(1) |> first()
        actor  = keep(Int)
        synced = sync(actor)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [ 0 ]
    end

    @testset begin
        source = completed(Int) |> first()

        values      = Int[]
        errors      = []
        completions = Int[]

        subscribe!(source, lambda(
            on_next     = d -> push!(values, d),
            on_error    = e -> push!(errors, e),
            on_complete = () -> push!(completions, 1)
        ))

        @test isempty(values)      === true
        @test isempty(errors)      === false
        @test isempty(completions) === true

        @test errors[1] isa FirstNotFoundException
    end

end

end

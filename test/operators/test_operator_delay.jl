module RocketDelayOperatorTest

using Test
using Rocket

# TODO: operator testset

@testset "operator: delay()" begin

    @testset begin
        source = of(2) |> delay(20)
        actor  = keep(Int)
        synced = sync(actor)

        subscription = subscribe!(source, synced)

        @test isempty(actor.values) === true

        elapsed = @elapsed wait(synced)

        @test actor.values == [ 2 ]
        @test elapsed      >   0.015
    end

    @testset begin
        source = completed(Int) |> delay(20)
        actor  = keep(Int)
        synced = sync(actor)

        subscription = subscribe!(source, synced)

        @test isempty(actor.values) === true

        elapsed = @elapsed wait(synced)

        @test isempty(actor.values) === true
        @test elapsed      >   0.015
    end

end

end

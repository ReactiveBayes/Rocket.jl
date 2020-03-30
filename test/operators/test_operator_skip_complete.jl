module RocketSkipCompleteOperatorTest

using Test
using Rocket

@testset "operator: skip_complete()" begin

    @testset begin
        values = Int[]
        source = completed(Int) |> skip_complete()

        @test values == []

        subscribe!(source |> tap_on_complete(() -> push!(values, 1)), void())

        @test values == [ ]
    end

end

end

module RocketFilterOperatorTest

using Test
using Rocket

@testset "operator: filter()" begin

    @testset begin
        source = from(1:5) |> filter(d -> d % 2 == 0)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 2, 4 ]
    end

end

end

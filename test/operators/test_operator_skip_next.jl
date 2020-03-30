module RocketSkipNextOperatorTest

using Test
using Rocket

@testset "operator: skip_next()" begin

    @testset begin
        source = from(1:5) |> skip_next()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

end

end

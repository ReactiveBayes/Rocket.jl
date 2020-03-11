module RocketDefaultIfEmptyOperatorTest

using Test
using Rocket

@testset "operator: default_if_empty()" begin

    @testset begin
        source = from(1:5) |> default_if_empty(0)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 4, 5 ]
    end

    @testset begin
        source = completed(Int) |> default_if_empty(0)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 0 ]
    end

end

end

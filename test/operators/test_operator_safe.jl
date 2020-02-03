module RocketSafeOperatorTest

using Test
using Rocket

@testset "operator: safe()" begin

    @testset begin
        source = from(1:5) |> safe()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 4, 5 ]
    end

    @testset begin
        source = throwError("Error", Int) |> safe() |> catch_error((err, obs) -> of(2))
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 2 ]
    end

end

end

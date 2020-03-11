module RocketErrorIfEmptyOperatorTest

using Test
using Rocket

@testset "operator: error_if_empty()" begin

    @testset begin
        source = from(1:5) |> error_if_empty("Empty")
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 4, 5 ]
    end

    @testset begin
        source = completed(Int) |> error_if_empty("Empty")
        actor  = keep(Int)

        @test_throws ErrorException subscribe!(source, actor)
    end

    @testset begin
        source = completed(Int) |> safe() |> error_if_empty("Empty") |> catch_error((d, obs) -> of(1))
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1 ]
    end

end

end

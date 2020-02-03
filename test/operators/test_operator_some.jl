module RocketSomeOperatorTest

using Test
using Rocket

@testset "operator: some()" begin

    @testset begin
        source = from(1:42) |> max() |> some()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 42 ]
    end

    @testset begin
        source = from([ 2, 3, 4, nothing ]) |> some()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 2, 3, 4 ]
    end

    @testset begin
        source = completed(Int) |> max() |> some()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

end

end

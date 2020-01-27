module RxToArrayOperatorTest

using Test
using Rx

@testset "operator: to_array()" begin

    @testset begin
        source = from(1:5) |> to_array()
        actor  = keep(Vector{Int})

        subscribe!(source, actor)

        @test actor.values == [[1, 2, 3, 4, 5]]
    end

    @testset begin
        source = from("Hello, world") |> to_array()
        actor  = keep(Vector{Char})

        subscribe!(source, actor)

        @test actor.values == [['H', 'e', 'l', 'l', 'o', ',', ' ', 'w', 'o', 'r', 'l', 'd']]
    end

end

end

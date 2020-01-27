module RxCatchErrorOperatorTest

using Test
using Rx

@testset "catch_error operator" begin

    source1 = from(1:5) |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> from(1:3))
    actor1  = keep(Int)

    subscribe!(source1, actor1)

    @test actor1.values == [ 1, 2, 3, 1, 2, 3 ]

    source2 = from(1:5) |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> obs) |> take(10)
    actor2  = keep(Int)

    subscribe!(source2, actor2)

    @test actor2.values == [1, 2, 3, 1, 2, 3, 1, 2, 3, 1]

    source3 = from(1:5) |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> throw("err"))
    actor3  = keep(Int)

    @test_throws ErrorException("err") subscribe!(source3, actor3)
    @test actor3.values == [ 1, 2, 3 ]
end

end

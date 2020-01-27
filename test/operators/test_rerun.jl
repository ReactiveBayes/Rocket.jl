module RxCatchErrorOperatorTest

using Test
using Rx

@testset "rerun operator" begin

    source1 = from(1:5) |> map(Int, (d) -> d == 4 ? error(4) : d) |> rerun(3)
    actor1  = keep(Int)

    @test_throws ErrorException subscribe!(source1, actor1)
    @test actor1.values == [1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3]


    values2  = []
    source2 = timer(0, 1) |> map(Int, (d) -> d > 2 ? error("d") : d) |> rerun(2)
    actor2  = sync(LambdaActor{Int}(
        on_next     = (d) -> push!(values2, d),
        on_error    = (e) -> push!(values2, e),
        on_complete = ()  -> push!(values2, "completed")
    ))

    subscribe!(source2, actor2)

    wait(actor2)

    @test values2 == [0, 1, 2, 0, 1, 2, 0, 1, 2, ErrorException("d")]

    values3 = []
    source3 = timer(0, 1) |> switchMap(Int, (d) -> d > 1 ? throwError("$d", Int) : of(d)) |> rerun(2)
    actor3  = sync(LambdaActor{Int}(
        on_next     = (d) -> push!(values3, d),
        on_error    = (e) -> push!(values3, e),
        on_complete = ()  -> push!(values3, "completed")
    ))

    subscribe!(source3, actor3)

    wait(actor3)

    @test values3 == [0, 1, 0, 1, 0, 1, "2"]
end

end

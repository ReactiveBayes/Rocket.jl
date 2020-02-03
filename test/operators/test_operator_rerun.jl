module RocketRerunOperatorTest

using Test
using Rocket

@testset "operator: rerun()" begin

    @testset begin
        source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> rerun(3)
        actor  = keep(Int)

        @test_throws ErrorException subscribe!(source, actor)
        @test actor.values == [1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3]
    end

    @testset begin
        values  = []
        source = timer(0, 1) |> safe() |> map(Int, (d) -> d > 2 ? error("d") : d) |> rerun(2)
        actor  = sync(LambdaActor{Int}(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        ))

        subscribe!(source, actor)
        wait(actor)

        @test values == [0, 1, 2, 0, 1, 2, 0, 1, 2, ErrorException("d")]
    end

    @testset begin
        values = []
        source = timer(0, 1) |> safe() |> switchMap(Int, (d) -> d > 1 ? throwError("$d", Int) : of(d)) |> rerun(2)
        actor  = sync(LambdaActor{Int}(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        ))

        subscribe!(source, actor)
        wait(actor)

        @test values == [0, 1, 0, 1, 0, 1, "2"]
    end
end

end

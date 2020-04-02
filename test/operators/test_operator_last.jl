module RocketLastOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: last()" begin

    run_testset([

        (
            source = from(1:42) |> last(),
            values = @ts([ 42 ] ~ c)
        ),
        (
            source = timer(50, 10) |> take(10) |> last(),
            values = @ts(150 ~ [ 9 ] ~ c)
        ),
        (
            source = completed() |> last(),
            values = @ts(e(LastNotFoundException()))
        ),
        (
            source      = completed(Int) |> last(default = "String"),
            values      = @ts([ "String" ] ~ c),
            source_type = Union{Int, String}
        ),
        (
            source      = throwError("e", Int) |> last(),
            values      = @ts(e("e")),
            source_type = Union{Int}
        ),
        (
            source      = throwError("e", Int) |> last(default = "String"),
            values      = @ts(e("e")),
            source_type = Union{Int, String}
        ),
        (
            source = never() |> last(),
            values = @ts()
        )
    ])

end

end

module RocketSafeOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: safe()" begin

    run_testset([
        (
            source = from(1:5) |> safe(),
            values = @ts([ 1:5 ] ~ c)
        ),
        (
            source = from([ 0, 1, 2 ]) |> safe() |> map(Int, d -> d === 0 ? 0 : throw(d)),
            values = @ts([ 0 ] ~ e(1))
        ),
        (
            source = completed() |> safe(),
            values = @ts(c)
        ),
        (
            source      = throwError("e") |> safe(),
            values      = @ts(e("e"))
        ),
        (
            source = never() |> safe(),
            values = @ts()
        )
    ])

end

end

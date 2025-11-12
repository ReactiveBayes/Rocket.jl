module RocketIgnoreOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: ignore()" begin

    println("Testing: operator ignore()")

    run_proxyshowcheck("Ignore", ignore(0))

    run_testset([
        (source = from(1:3) |> ignore(-1), values = @ts([1, 2, 3, c])),
        (source = from(1:3) |> ignore(0), values = @ts([1, 2, 3, c])),
        (source = from(1:3) |> ignore(1), values = @ts([2, 3, c])),
        (source = from(1:3) |> ignore(2), values = @ts([3, c])),
        (source = from(1:3) |> ignore(3), values = @ts(c)),
        (source = from(1:3) |> ignore(4), values = @ts(c)),
        (source = from(1:3) |> async(0) |> ignore(2), values = @ts([3] ~ c)),
        (source = completed(Int) |> ignore(2), values = @ts(c)),
        (source = never(Int) |> ignore(2), values = @ts()),
        (source = faulted("e") |> ignore(2), values = @ts(e("e"))),
    ])

end

end

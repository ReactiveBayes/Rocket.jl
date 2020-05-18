module RocketTupleWithOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: tuple_with_*()" begin

    println("Testing: operator tuple_with_*()")

    run_proxyshowcheck("TupleWithLeft", tuple_with_left(0))
    run_proxyshowcheck("TupleWithRight", tuple_with_right(0))

    run_testset([
        (
            source = from(1:3) |> tuple_with_left('0'),
            values = @ts([ ('0', 1), ('0', 2), ('0', 3), c ]),
            source_type = Tuple{Char, Int}
        ),
        (
            source = completed(Int) |> tuple_with_left('0'),
            values = @ts(c),
            source_type = Tuple{Char, Int}
        ),
        (
            source = never(Int) |> tuple_with_left('0'),
            values = @ts(),
            source_type = Tuple{Char, Int}
        ),
        (
            source = faulted("e") |> tuple_with_left('0'),
            values = @ts(e("e"))
        )
    ])

    run_testset([
        (
            source = from(1:3) |> tuple_with_right('0'),
            values = @ts([ (1, '0'), (2, '0'), (3, '0'), c ]),
            source_type = Tuple{Int, Char}
        ),
        (
            source = completed(Int) |> tuple_with_right('0'),
            values = @ts(c),
            source_type = Tuple{Int, Char}
        ),
        (
            source = never(Int) |> tuple_with_right('0'),
            values = @ts(),
            source_type = Tuple{Int, Char}
        ),
        (
            source = faulted("e") |> tuple_with_right('0'),
            values = @ts(e("e"))
        )
    ])

end

end

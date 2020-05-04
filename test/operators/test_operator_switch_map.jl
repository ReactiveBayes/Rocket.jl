module RocketSwitchMapOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: switch_map()" begin

    println("Testing: operator switch_map()")

    run_proxyshowcheck("SwitchMap", switch_map(Any), args = (check_subscription = true, ))

    run_testset([
        (
            source      = from(1:5) |> switch_map(Int, d -> of(d ^ 2)),
            values      = @ts([ 1, 4, 9, 16, 25, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> switch_map(Float64, d -> of(convert(Float64, d))),
            values      = @ts([ 1.0, 2.0, 3.0, 4.0, 5.0, c ]),
            source_type = Float64
        ),
        (
            source      = completed() |> switch_map(Int, d -> of(1)),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = throwError(Int, "e") |> switch_map(String, d -> string(d)),
            values      = @ts(e("e")),
            source_type = String
        ),
        (
            source      = never() |> switch_map(Int, d -> of(1)),
            values      = @ts(),
            source_type = Int
        ),
        (
            source      = from(1:5) |> switch_map(Int, d -> of(1.0)), # Invalid output: Float64 instead of Int
            values      = @ts(),
            source_type = Int,
            throws      = Exception
        ),
        (
            source      = from(1:5) |> safe() |> switch_map(Int, d -> of(1.0)), # Invalid output: Float64 instead of Int
            values      = @ts(e),
            source_type = Int
        ),
        (
            source      = from(1:5) |> async(0) |> switch_map(Int, d -> of(d ^ 2)),
            values      = @ts([ 1 ] ~ [ 4 ] ~ [ 9 ] ~ [ 16 ] ~ [ 25 ] ~ c),
            source_type = Int
        ),
        (
            source      = from([ of(1), completed(Int), of(2) ]) |> switch_map(Int),
            values      = @ts([ 1, 2, c ]),
            source_type = Int
        ),
        (
            source      = from([ of(1), completed(Int), of(2) ]) |> async(0) |> switch_map(Int),
            values      = @ts([ 1 ] ~ [ 2 ] ~ c ),
            source_type = Int
        ),
        (
            source      = from([ of(1), throwError(Int, "err"), of(2) ]) |> switch_map(Int),
            values      = @ts([ 1, e("err") ]),
            source_type = Int
        ),
        (
            source      = from([ of(1), throwError(Int, "err"), of(2) ]) |> async(0) |> switch_map(Int),
            values      = @ts([ 1 ] ~ e("err")),
            source_type = Int
        )
    ])

    @testset begin
        subject1 = Subject(Int)
        subject2 = Subject(Int)

        values = []

        ssubject = Subject(Any)

        source = ssubject |> switch_map(Int)

        subscription = subscribe!(source, (d) -> push!(values, d))

        @test values == []

        next!(ssubject, subject1)
        next!(subject1, 1)
        next!(subject2, 2)

        @test values == [ 1 ]

        next!(ssubject, subject2)
        next!(subject1, 1)
        next!(subject2, 2)

        @test values == [ 1, 2 ]

        next!(ssubject, subject2)
        next!(subject1, 1)
        next!(subject2, 2)

        @test values == [ 1, 2, 2 ]

        unsubscribe!(subscription)

        next!(ssubject, subject1)
        next!(subject1, 1)
        next!(subject2, 2)

        @test values == [ 1, 2, 2 ]

        next!(ssubject, subject2)
        next!(subject1, 1)
        next!(subject2, 2)

        @test values == [ 1, 2, 2 ]
    end

end

end

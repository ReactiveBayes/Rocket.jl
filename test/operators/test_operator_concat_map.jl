module RocketExhaustMapOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: exhaust_map()" begin

    println("Testing: operator exhaust_map()")

    run_proxyshowcheck("ExhaustMap", exhaust_map(Any), args = (check_subscription = true, ))

    run_testset([
        (
            source      = from(1:5) |> exhaust_map(Int, d -> of(d ^ 2)),
            values      = @ts([ 1, 4, 9, 16, 25, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> exhaust_map(Float64, d -> of(convert(Float64, d))),
            values      = @ts([ 1.0, 2.0, 3.0, 4.0, 5.0, c ]),
            source_type = Float64
        ),
        (
            source      = from(1:5) |> exhaust_map(Float64, _ -> throwError(Float64, "err")),
            values      = @ts(e("err")),
            source_type = Float64
        ),
        (
            source      = from(1:5) |> exhaust_map(Float64, _ -> completed(Float64)),
            values      = @ts(c),
            source_type = Float64
        ),
        (
            source      = from(1:5) |> exhaust_map(Float64, _ -> never(Float64)),
            values      = @ts(),
            source_type = Float64
        ),
        (
            source      = completed() |> exhaust_map(Int, d -> of(1)),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = throwError(Int, "e") |> exhaust_map(String, d -> string(d)),
            values      = @ts(e("e")),
            source_type = String
        ),
        (
            source      = never() |> exhaust_map(Int, d -> of(1)),
            values      = @ts(),
            source_type = Int
        ),
        (
            source      = from(1:5) |> exhaust_map(Int, d -> of(1.0)), # Invalid output: Float64 instead of Int
            values      = @ts(),
            source_type = Int,
            throws      = Exception
        ),
        (
            source      = from(1:5) |> safe() |> exhaust_map(Int, d -> of(1.0)), # Invalid output: Float64 instead of Int
            values      = @ts(e),
            source_type = Int
        ),
        (
            source      = from(1:5) |> async(0) |> exhaust_map(Int, d -> of(d ^ 2)),
            values      = @ts([ 1 ] ~ [ 4 ] ~ [ 9 ] ~ [ 16 ] ~ [ 25 ] ~ c),
            source_type = Int
        ),
        (
            source      = from([ of(1), completed(Int), of(2) ]) |> exhaust_map(Int),
            values      = @ts([ 1, 2, c ]),
            source_type = Int
        ),
        (
            source      = from([ of(1), completed(Int), of(2) ]) |> async(0) |> exhaust_map(Int),
            values      = @ts([ 1 ] ~ [ 2 ] ~ c ),
            source_type = Int
        ),
        (
            source      = from([ of(1), throwError(Int, "err"), of(2) ]) |> exhaust_map(Int),
            values      = @ts([ 1, e("err") ]),
            source_type = Int
        ),
        (
            source      = from([ of(1), throwError(Int, "err"), of(2) ]) |> async(0) |> exhaust_map(Int),
            values      = @ts([ 1 ] ~ e("err")),
            source_type = Int
        ),
        (
            source      = from([ 0, 0 ]) |> exhaust_map(Int, d -> from([ 1, 2 ])),
            values      = @ts([ 1, 2, 1, 2, c ]),
            source_type = Int
        ),
        (
            source      = from([ 1, 2 ]) |> async(0) |> exhaust_map(Int, d -> from([ d, d ]) |> async(0)),
            values      = @ts([ 1 ] ~ [ 1 ] ~ c),
            source_type = Int
        )
    ])

    customsource1 = make(Int) do actor
        subject1 = Subject(Int)
        subject2 = Subject(Int)
        ssubject = Subject(Any)
        source   = ssubject |> exhaust_map(Int)

        subscribe!(source, lambda(
            on_next     = (d) -> next!(actor, d),
            on_error    = (e) -> error!(actor, e),
            on_complete = () -> complete!(actor)
        ))

        @async begin
            next!(ssubject, subject1)
            next!(subject1, 1)
            next!(subject2, 2)
            @async begin
                next!(ssubject, subject2)
                next!(subject1, 3)
                next!(subject2, 4)
                complete!(subject1)
                @async begin
                    next!(subject1, 5)
                    next!(subject2, 6)
                    complete!(ssubject)
                end
            end
        end
    end

    run_testset([ ( source = customsource1, values = @ts([ 1 ] ~ [ 3 ] ~ c) ) ])

    customsource2 = make(Int) do actor
        ssubject = Subject(Any)
        source   = ssubject |> exhaust_map(Int)

        subscribe!(source, lambda(
            on_next     = (d) -> next!(actor, d),
            on_error    = (e) -> error!(actor, e),
            on_complete = () -> complete!(actor)
        ))

        @async begin
            next!(ssubject, from([ 1, 2, 3 ]))
            complete!(ssubject)
            next!(ssubject, from([ 1, 2, 3 ])) # should be skipped
        end
    end

    run_testset([ ( source = customsource2, values = @ts([ 1, 2, 3, c ]) ) ])

    customsource3 = make(Int) do actor
        ssubject = Subject(Any)
        source   = ssubject |> exhaust_map(Int)

        subscribe!(source, lambda(
            on_next     = (d) -> next!(actor, d),
            on_error    = (e) -> error!(actor, e),
            on_complete = ()  -> complete!(actor)
        ))

        @async begin
            complete!(ssubject)
            next!(ssubject, from([ 1, 2, 3 ]))
            next!(ssubject, from([ 1, 2, 3 ])) # should be skipped
        end
    end

    run_testset([ ( source = customsource3, values = @ts(c) ) ])

    customsource4 = make(Int) do actor
        subject1 = Subject(Int)
        subject2 = Subject(Int)
        ssubject = Subject(Any)
        source   = ssubject |> exhaust_map(Int)

        subscribe!(source, lambda(
            on_next     = (d) -> next!(actor, d),
            on_error    = (e) -> error!(actor, e),
            on_complete = ()  -> complete!(actor)
        ))

        @async begin
            next!(ssubject, of(0))
            next!(ssubject, subject1)
            next!(ssubject, subject2)
            complete!(ssubject)
            @async begin
                next!(subject1, 1)
                next!(subject2, 2)
                complete!(subject1)
                @async begin
                    next!(subject2, 3)
                    complete!(subject2)
                    next!(ssubject, from([ 1, 2, 3 ])) # should be skipped
                end
            end
        end
    end

    run_testset([ ( source = customsource4, values = @ts([ 0 ] ~ [ 1, c ]) ) ])

end

end

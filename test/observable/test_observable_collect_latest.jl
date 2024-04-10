module RocketCollectLatestObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "CollectLatestObservable" begin

    println("Testing: collectLatest")

    run_testset([
        (
            source = collectLatest([ of(1), from(1:5) ]),
            values = @ts([ [1, 1], [1, 2], [1, 3], [1, 4], [1, 5], c ]),
            source_type = Vector{Int}
        ),
        (
            source = collectLatest([ of(1), from(1:5) ], (v) -> v .^ 2),
            values = @ts([ [1, 1], [1, 4], [1, 9], [1, 16], [1, 25], c ]),
            source_type = Vector{Int}
        ),
        (
            source = collectLatest(Int, Int, [ of(1), from(1:5) ], sum),
            values = @ts([ 2, 3, 4, 5, 6, c ]),
            source_type = Int
        ),
        (
            source = collectLatest([ of(1) |> async(0), from(1:5) ]),
            values = @ts([ [1, 5] ] ~ c),
            source_type = Vector{Int}
        ),
        (
            source = collectLatest([ of(1) |> async(0), from(1:5) |> async(0) ]),
            values = @ts([ [1, 1] ] ~ [ [1, 2] ] ~ [ [1, 3] ] ~ [ [1, 4] ] ~ [ [1, 5] ] ~ c),
            source_type = Vector{Int}
        ),
        (
            source = collectLatest([ from(1:5), of(2.0) ]),
            values = @ts([ [5, 2], c ]),
            source_type = Vector{Union{Float64, Int}}
        ),
        (
            source = collectLatest([ from(1:5) |> async(0), of(2.0) ]),
            values = @ts([ [1, 2.0] ] ~ [ [2, 2.0] ] ~ [ [3, 2.0] ] ~ [ [4, 2.0] ] ~ [ [5, 2.0] ] ~ c),
            source_type = Vector{Union{Float64, Int}}
        ),
        (
            source = collectLatest([ completed(Int), of(1) ]),
            values = @ts(c),
            source_type = Vector{Int}
        ),
        (
            source = collectLatest([ completed(Int), completed(Int) ]),
            values = @ts(c),
            source_type = Vector{Int}
        ),
        (
            source = collectLatest([ faulted(Float64, "err"), completed(Int) ]),
            values = @ts(e("err")),
            source_type = Vector{Union{Float64, Int}}
        ),
        (
            source = collectLatest([ completed(Int), faulted(Float64, "err") ]),
            values = @ts(c),
            source_type = Vector{Union{Float64, Int}}
        ),
        (
            source = collectLatest([ faulted(Float64, "err1"), faulted(Float64, "err2") ]),
            values = @ts(e("err1")),
            source_type = Vector{Float64}
        ),
        (
            source = collectLatest([ of(1) of(2); of(3) of(4) ]),
            values = @ts([ [ 1 2; 3 4 ], c ]),
            source_type = Matrix{Int}
        ),
        (
            source = collectLatest([ of(1) of(2.0); of(3.0) of(4) ]),
            values = @ts([ [ 1 2.0; 3.0 4 ], c ]),
            source_type = Matrix{Union{Int, Float64}}
        ),
        (
            source      = collectLatest([]),
            values      = @ts(c),
            source_type = Vector{Union{}}
        )
    ])

    somenumbers    = Union{Float64, Int}[ 1, 1, 1, 1, 1.0, 1.0, 1.0, 1.0 ]
    expectedoutput = somenumbers

    collected100 = collectLatest(map(n -> of(n), somenumbers))

    run_testset([
        (
            source = collected100,
            values = @ts([ [ 1, 1, 1, 1, 1.0, 1.0, 1.0, 1.0 ], c ]),
            source_type = Vector{Union{Float64, Int}}
        )
    ])


    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)
        s3 = Subject(String)
        s4 = of(5)
        s5 = from(1:10)

        latest = collectLatest([ s1, s2, s3, s4, s5 ])
        values = Vector{Any}()
        subscription = subscribe!(latest, lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        ))

        @test values == [ ]

        next!(s1, 1)

        @test values == [ ]

        next!(s2, 2.0)

        @test values == [ ]

        next!(s3, "Hello")

        @test values == [ [1, 2.0, "Hello", 5, 10] ]

        next!(s1, 2)

        @test values == [ [1, 2.0, "Hello", 5, 10] ]

        next!(s3, "Hello, world!")

        @test values == [ [1, 2.0, "Hello", 5, 10]  ]

        complete!(s1);

        next!(s2, 3.0)

        @test values == [ [1, 2.0, "Hello", 5, 10], [2, 3.0, "Hello, world!", 5, 10]  ]

        complete!(s2)

        @test values == [ [1, 2.0, "Hello", 5, 10], [2, 3.0, "Hello, world!", 5, 10] ]

        next!(s3, "Something")

        @test values == [ [1, 2.0, "Hello", 5, 10], [2, 3.0, "Hello, world!", 5, 10], [2, 3.0, "Something", 5, 10] ]

        complete!(s3)

        @test values == [ [1, 2.0, "Hello", 5, 10], [2, 3.0, "Hello, world!", 5, 10], [2, 3.0, "Something", 5, 10], "completed" ]

        unsubscribe!(subscription)
    end

    @testset begin 
        source1 = Subject(Int)
        source2 = Subject(Int)

        callbackCalled = []
        callbackFn = (wrapper, value) -> begin 
            # We reset the state of the `vstatus`
            if isequal(value, "2")
                Rocket.fill_vstatus!(wrapper, true)
                push!(callbackCalled, true)
            else
                push!(callbackCalled, false)
            end
        end

        combined = collectLatest(Int, String, [ source1, source2 ], (values) -> string(sum(values)), callbackFn)
        values = []
        subscription = subscribe!(combined, (value) -> push!(values, value))

        @test values == []
        @test callbackCalled == []
        next!(source1, 0)
        @test values == []
        @test callbackCalled == []
        next!(source2, 0)
        @test values == ["0"]
        @test callbackCalled == [false]

        next!(source1, 1)
        @test values == ["0"]
        @test callbackCalled == [false]
        next!(source2, 1)
        @test values == ["0", "2"]
        @test callbackCalled == [false, true]

        next!(source1, 2)
        @test values == ["0", "2", "3"] # this is hapenning because the callback should have been called
        @test callbackCalled == [false, true, false]
        next!(source1, 2)
        @test values == ["0", "2", "3"]
        @test callbackCalled == [false, true, false]
        next!(source2, 2)
        @test values == ["0", "2", "3", "4"]
        @test callbackCalled == [false, true, false, false]
    end

end

end

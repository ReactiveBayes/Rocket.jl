module RocketCombineLatestUpdatesObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "CombineLatestUpdatesObservable" begin

    println("Testing: combineLatestUpdates")

    @testset begin
        @test_throws ErrorException combineLatestUpdates()
    end

    run_testset([
        (
            source = combineLatestUpdates(completed(Int), of(1)),
            values = @ts(c),
            source_type = Tuple{ typeof(completed(Int)) , typeof(of(1)) }
        ),
        (
            source = combineLatestUpdates(completed(Int), completed(Int)),
            values = @ts(c),
            source_type = Tuple{ typeof(completed(Int)) , typeof(completed(Int)) }
        ),
        (
            source = combineLatestUpdates(faulted(Float64, "err"), completed(Int)),
            values = @ts(e("err")),
            source_type = Tuple{ typeof(faulted(Float64, "err")) , typeof(completed(Int)) }
        ),
        (
            source = combineLatestUpdates(completed(Int), faulted(Float64, "err")),
            values = @ts(c),
            source_type = Tuple{ typeof(completed(Int)) , typeof(faulted(Float64, "err")) }
        ),
        (
            source = combineLatestUpdates(faulted(Float64, "err1"), faulted(Float64, "err1")),
            values = @ts(e("err1")),
            source_type = Tuple{ typeof(faulted(Float64, "err1")) , typeof(faulted(Float64, "err1")) }
        ),
        (
            source = combineLatestUpdates(completed(Int), of(1), strategy = PushNew()),
            values = @ts(c),
            source_type = Tuple{ typeof(completed(Int)) , typeof(of(1)) }
        ),
        (
            source = combineLatestUpdates(completed(Int), completed(Int), strategy = PushNew()),
            values = @ts(c),
            source_type = Tuple{ typeof(completed(Int)) , typeof(completed(Int)) }
        ),
        (
            source = combineLatestUpdates(faulted(Float64, "err"), completed(Int), strategy = PushNew()),
            values = @ts(e("err")),
            source_type = Tuple{ typeof(faulted(Float64, "err")) , typeof(completed(Int)) }
        ),
        (
            source = combineLatestUpdates(completed(Int), faulted(Float64, "err"), strategy = PushNew()),
            values = @ts(c),
            source_type = Tuple{ typeof(completed(Int)) , typeof(faulted(Float64, "err")) }
        ),
        (
            source = combineLatestUpdates(faulted(Float64, "err1"), faulted(Float64, "err2"), strategy = PushNew()),
            values = @ts(e("err1")),
            source_type = Tuple{ typeof(faulted(Float64, "err1")) , typeof(faulted(Float64, "err2")) }
        ),
        (
            source      = combineLatestUpdates((), PushNew()),
            values      = @ts(c),
            source_type = Tuple{}
        ),
        (
            source      = combineLatestUpdates((), PushEach()),
            values      = @ts(c),
            source_type = Tuple{}
        )
    ])

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)
        s3 = Subject(String)
        s4 = of(5)
        s5 = from(1:10)

        latest = combineLatestUpdates(s1, s2, s3, s4, s5)
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

        @test values == [ (s1, s2, s3, s4, s5) ]

        next!(s1, 2)

        @test values == [ (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5) ]

        next!(s3, "Hello, world!")

        @test values == [ (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5)  ]

        complete!(s1);

        next!(s2, 3.0)

        @test values == [ (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5)  ]

        complete!(s2)

        @test values == [ (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5)  ]

        unsubscribe!(subscription)
    end

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)
        s3 = Subject(String)
        s4 = of(5)
        s5 = from(1:10)

        latest = combineLatestUpdates(s1, s2, s3, s4, s5, strategy = PushNew())
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

        @test values == [ (s1, s2, s3, s4, s5) ]

        next!(s1, 2)

        @test values == [ (s1, s2, s3, s4, s5) ]

        next!(s3, "Hello, world!")

        @test values == [ (s1, s2, s3, s4, s5)  ]

        complete!(s1);

        next!(s2, 3.0)

        @test values == [ (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5)  ]

        complete!(s2)

        @test values == [ (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5)  ]

        next!(s3, "Something")

        @test values == [ (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5)  ]

        complete!(s3)

        @test values == [ (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5), (s1, s2, s3, s4, s5), "completed"  ]

        unsubscribe!(subscription)
    end

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)
        s3 = Subject(String)

        latest = combineLatestUpdates(s1, s2, s3, strategy = PushNewBut{1}())
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

        @test values == [ (s1, s2, s3) ]

        next!(s2, 3.0)

        @test values == [ (s1, s2, s3) ]

        next!(s3, "Hello, world!")

        @test values == [ (s1, s2, s3), (s1, s2, s3) ]

        next!(s1, 2)

        @test values == [ (s1, s2, s3), (s1, s2, s3) ]

        next!(s1, 3)

        @test values == [ (s1, s2, s3), (s1, s2, s3) ]

        next!(s1, 4)

        @test values == [ (s1, s2, s3), (s1, s2, s3) ]

        next!(s2, 4.0)

        @test values == [ (s1, s2, s3), (s1, s2, s3) ]

        next!(s3, "")

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        complete!(s1);

        next!(s2, 5.0)

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        next!(s3, "foo")

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        complete!(s2)

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        next!(s3, "bar")

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        complete!(s3)

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), "completed" ]

        unsubscribe!(subscription)
    end

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)
        s3 = Subject(String)

        latest = combineLatestUpdates(s1, s2, s3, strategy = PushStrategy(BitArray([ false, true, false ])))
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

        @test values == [ (s1, s2, s3) ]

        next!(s2, 3.0)

        @test values == [ (s1, s2, s3) ]

        next!(s3, "Hello, world!")

        @test values == [ (s1, s2, s3) ]

        next!(s1, 2)

        @test values == [ (s1, s2, s3), (s1, s2, s3) ]

        next!(s1, 3)

        @test values == [ (s1, s2, s3), (s1, s2, s3) ]

        next!(s1, 4)

        @test values == [ (s1, s2, s3), (s1, s2, s3) ]

        next!(s2, 4.0)

        @test values == [ (s1, s2, s3), (s1, s2, s3) ]

        next!(s3, "")

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        complete!(s1);

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        next!(s2, 5.0)

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        next!(s3, "1")

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        complete!(s3)

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        next!(s2, 6.0)

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3) ]

        complete!(s2)

        @test values == [ (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), (s1, s2, s3), "completed" ]

        unsubscribe!(subscription)
    end

    @testset begin 
        source1 = RecentSubject(Int)
        source2 = RecentSubject(Int)

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

        combined = combineLatestUpdates((source1, source2), PushNew(), String, (sources) -> string(sum(Rocket.getrecent.(sources))), callbackFn)
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

module RocketPrioritizeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

import Rocket: priorities, postponed, release!, ispriority, setpriority!

@testset "operator: prioritize()" begin

    println("Testing: operator prioritize()")

    run_proxyshowcheck("Prioritize", prioritize(PriorityHandler((:a, :b)), :a), args = (check_subscription = true, ))

    @testset begin
        handler = PriorityHandler((:a, :b))

        @test priorities(handler) === (:a, :b)
        @test ispriority(handler, :a)

        setpriority!(handler, :a)
        @test ispriority(handler, :a)
        setpriority!(handler, :b)
        @test ispriority(handler, :b)
    end

    @testset begin 
        @test_throws AssertionError PriorityHandler((:a, :b), :c)
        @test_throws AssertionError setpriority!(PriorityHandler((:a, :b)), :c)
    end
    
    @testset begin 
        handler = PriorityHandler((:a, :b))

        source1 = from([ 1, 2 ]) |> prioritize(handler, :a)
        source2 = from([ 3, 4 ]) |> prioritize(handler, :b)

        events = []

        subscription1 = subscribe!(source1, lambda(
            on_next     = (v) -> push!(events, v),
            on_complete = () -> push!(events, "c1")
        ))
        subscription2 = subscribe!(source2, lambda(
            on_next     = (v) -> push!(events, v),
            on_complete = () -> push!(events, "c2")
        ))

        @test events == [ 1, 2, "c1", 3, 4, "c2" ]

        setpriority!(handler, :a)
        @test events == [ 1, 2, "c1", 3, 4, "c2" ]
        setpriority!(handler, :b)
        @test events == [ 1, 2, "c1", 3, 4, "c2" ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
    end

    @testset begin 
        handler = PriorityHandler((:a, :b))

        source1 = from([ 1, 2 ]) |> prioritize(handler, :a)
        source2 = from([ 3, 4 ]) |> prioritize(handler, :b, false)

        events = []

        subscription1 = subscribe!(source1, lambda(
            on_next     = (v) -> push!(events, v),
            on_complete = () -> push!(events, "c1")
        ))
        subscription2 = subscribe!(source2, lambda(
            on_next     = (v) -> push!(events, v),
            on_complete = () -> push!(events, "c2")
        ))

        @test events == [ 1, 2, "c1", "c2" ]

        setpriority!(handler, :a)
        @test events == [ 1, 2, "c1", "c2" ]
        setpriority!(handler, :b)
        @test events == [ 1, 2, "c1", "c2" ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
    end

    @testset begin 
        handler = PriorityHandler((:a, :b))

        source1 = Subject(Int)
        source2 = Subject(Int)

        events = []

        subscription1 = subscribe!(source1 |> prioritize(handler, :a), lambda(
            on_next     = (v) -> push!(events, v),
            on_complete = () -> push!(events, "c1")
        ))
        subscription2 = subscribe!(source2 |> prioritize(handler, :b), lambda(
            on_next     = (v) -> push!(events, v),
            on_complete = () -> push!(events, "c2")
        ))

        next!(source1, 1)
        next!(source1, 2)
        
        @test events == [ 1, 2 ]
        complete!(source1)
        @test events == [ 1, 2, "c1" ]

        unsubscribe!(subscription2)

        next!(source2, 3)
        next!(source2, 4)
        complete!(source2)

        setpriority!(handler, :a)
        @test events == [ 1, 2, "c1" ]
        setpriority!(handler, :b)
        @test events == [ 1, 2, "c1" ]

        unsubscribe!(subscription1)
    end

    @testset begin 
        handler = PriorityHandler((:a, :b))

        source1 = Subject(Int)
        source2 = Subject(Int)

        events = []

        subscription1 = subscribe!(source1 |> prioritize(handler, :a), lambda(
            on_next     = (v) -> push!(events, v),
            on_complete = () -> push!(events, "c1")
        ))
        subscription2 = subscribe!(source2 |> prioritize(handler, :b), lambda(
            on_next     = (v) -> push!(events, v),
            on_complete = () -> push!(events, "c2")
        ))

        next!(source1, 1)
        next!(source1, 2)

        @test events == [ 1, 2 ]
        complete!(source1)
        @test events == [ 1, 2, "c1" ]

        unsubscribe!(subscription1)

        next!(source2, 3)
        next!(source2, 4)

        setpriority!(handler, :a)
        @test events == [ 1, 2, "c1" ]
        setpriority!(handler, :b)
        @test events == [ 1, 2, "c1", 3, 4 ]
        unsubscribe!(subscription2)
        complete!(source2)
        @test events == [ 1, 2, "c1", 3, 4 ]
    end

    @testset begin 
        handler = PriorityHandler((:a, :b))

        source1 = Subject(Int)
        source2 = Subject(Int)

        events = []

        subscription1 = subscribe!(source1 |> prioritize(handler, :a), lambda(
            on_next     = (v) -> push!(events, v),
            on_error    = (e) -> push!(events, "e1"),
            on_complete = () -> push!(events, "c1")
        ))
        subscription2 = subscribe!(source2 |> prioritize(handler, :b), lambda(
            on_next     = (v) -> push!(events, v),
            on_error    = (e) -> push!(events, "e2"),
            on_complete = () -> push!(events, "c2")
        ))

        next!(source1, 1)
        next!(source1, 2)

        @test events == [ 1, 2 ]
        error!(source1, "error")
        @test events == [ 1, 2, "e1" ]

        unsubscribe!(subscription1)

        next!(source2, 3)
        next!(source2, 4)

        setpriority!(handler, :a)
        @test events == [ 1, 2, "e1" ]
        setpriority!(handler, :b)
        @test events == [ 1, 2, "e1", 3, 4 ]
        unsubscribe!(subscription2)
        complete!(source2)
        @test events == [ 1, 2, "e1", 3, 4 ]
    end

    @testset begin 
        handler = PriorityHandler((:a, :b))

        source1 = Subject(Int)
        source2 = Subject(Int)

        events = []

        subscription1 = subscribe!(source1 |> prioritize(handler, :a), lambda(
            on_next     = (v) -> push!(events, v),
            on_error    = (e) -> push!(events, "e1"),
            on_complete = () -> push!(events, "c1")
        ))
        subscription2 = subscribe!(source2 |> prioritize(handler, :b), lambda(
            on_next     = (v) -> push!(events, v),
            on_error    = (e) -> push!(events, "e2"),
            on_complete = () -> push!(events, "c2")
        ))

        next!(source1, 1)
        next!(source1, 2)

        @test events == [ 1, 2 ]
        error!(source2, "error")
        @test events == [ 1, 2, "e2" ]

        unsubscribe!(subscription1)

        next!(source2, 3)
        next!(source2, 4)

        setpriority!(handler, :a)
        @test events == [ 1, 2, "e2" ]
        setpriority!(handler, :b)
        @test events == [ 1, 2, "e2" ]
        unsubscribe!(subscription2)
        complete!(source2)
        @test events == [ 1, 2, "e2" ]
    end

    @testset begin 
        handler = PriorityHandler((:a, :b))

        source1 = Subject(Int)
        source2 = Subject(Int)

        events = []

        subscription1 = subscribe!(source1 |> prioritize(handler, :a), lambda(
            on_next     = (v) -> push!(events, v),
            on_error    = (e) -> push!(events, "e1"),
            on_complete = () -> push!(events, "c1")
        ))
        subscription2 = subscribe!(source2 |> prioritize(handler, :b), lambda(
            on_next     = (v) -> push!(events, v),
            on_error    = (e) -> push!(events, "e2"),
            on_complete = () -> push!(events, "c2")
        ))

        next!(source1, 1)
        next!(source1, 2)

        @test events == [ 1, 2 ]

        unsubscribe!(subscription1)

        next!(source2, 3)
        next!(source2, 4)
        error!(source2, "error")

        setpriority!(handler, :a)
        @test events == [ 1, 2, "e2" ]
        setpriority!(handler, :b)
        @test events == [ 1, 2, "e2" ]
        unsubscribe!(subscription2)
        complete!(source2)
        @test events == [ 1, 2, "e2" ]
    end

    @testset begin 
        handler = PriorityHandler((:a, :b))

        source1 = Subject(Int) 
        source2 = Subject(Int)

        events = []

        subscription1 = subscribe!(source1 |> prioritize(handler, :a), (v) -> push!(events, v))
        subscription2 = subscribe!(source2 |> prioritize(handler, :b), (v) -> push!(events, v))

        @test events == [ ]
        
        next!(source1, 1)
        next!(source2, 2)
        @test events == [ 1 ]
        setpriority!(handler, :b)
        @test events == [ 1, 2 ]
        next!(source1, 1)
        next!(source2, 2)
        @test events == [ 1, 2, 2 ]
        setpriority!(handler, :a)
        @test events == [ 1, 2, 2, 1 ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)

        next!(source1, 1)
        next!(source2, 2)
        @test events == [ 1, 2, 2, 1 ]
        setpriority!(handler, :a)
        @test events == [ 1, 2, 2, 1 ]
        setpriority!(handler, :b)
        @test events == [ 1, 2, 2, 1 ]
    end

    @testset begin 
        handler = PriorityHandler((:a, :b, :c))

        source1 = Subject(Int) 
        source2 = Subject(Int)
        source3 = Subject(Int)

        events = []

        subscription1 = subscribe!(source1 |> prioritize(handler, :a), (v) -> push!(events, v))
        subscription2 = subscribe!(source2 |> prioritize(handler, :b), (v) -> push!(events, v))
        subscription2 = subscribe!(source3 |> prioritize(handler, :c), (v) -> push!(events, v))

        @test events == [ ]
        
        next!(source1, 1)
        next!(source2, 2)
        next!(source2, 3)
        next!(source3, 4)
        next!(source3, 5)

        @test events == [ 1 ]
        release!(handler)
        @test events == [ 1, 2, 3, 4, 5 ]
    end
end

end

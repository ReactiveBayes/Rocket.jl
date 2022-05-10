module RocketPrioritySchedulerTest

using Test
using Rocket

import Rocket: priorities, postponed, release!, ispriority, setpriority!

@testset "PriorityScheduler" begin

    println("Testing: scheduler PriorityScheduler")

    @testset begin
        scheduler = PriorityScheduler((:a, :b))

        @test priorities(scheduler) === (:a, :b)
        @test ispriority(scheduler, :a)

        setpriority!(scheduler, :a)
        @test ispriority(scheduler, :a)
        setpriority!(scheduler, :b)
        @test ispriority(scheduler, :b)
    end

    @testset begin 
        @test_throws AssertionError PriorityScheduler((:a, :b), :c)
        @test_throws AssertionError setpriority!(PriorityScheduler((:a, :b)), :c)
    end
    
    @testset begin 
        scheduler = PriorityScheduler((:a, :b))

        source1 = from([ 1, 2 ]) |> map(Tuple{Symbol, Int}, d -> (:a, d)) |> schedule_on(scheduler)
        source2 = from([ 3, 4 ]) |> map(Tuple{Symbol, Int}, d -> (:b, d)) |> schedule_on(scheduler)

        events = []

        subscription1 = subscribe!(source1, (v) -> push!(events, v))
        subscription2 = subscribe!(source2, (v) -> push!(events, v))

        @test events == [ (:a, 1), (:a, 2) ]

        setpriority!(scheduler, :a)
        @test events == [ (:a, 1), (:a, 2) ]
        setpriority!(scheduler, :b)
        @test events == [ (:a, 1), (:a, 2), (:b, 3), (:b, 4) ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
    end

    @testset begin 
        scheduler = PriorityScheduler((:a, :b))

        source1 = Subject(Int) 
        source2 = Subject(Int)

        events = []

        subscription1 = subscribe!(source1 |> map(Tuple{Symbol, Int}, d -> (:a, d)) |> schedule_on(scheduler), (v) -> push!(events, v))
        subscription2 = subscribe!(source2 |> map(Tuple{Symbol, Int}, d -> (:b, d)) |> schedule_on(scheduler), (v) -> push!(events, v))

        @test events == [ ]
        
        next!(source1, 1)
        next!(source2, 2)
        @test events == [ (:a, 1) ]
        setpriority!(scheduler, :b)
        @test events == [ (:a, 1), (:b, 2) ]
        next!(source1, 1)
        next!(source2, 2)
        @test events == [ (:a, 1), (:b, 2), (:b, 2) ]
        setpriority!(scheduler, :a)
        @test events == [ (:a, 1), (:b, 2), (:b, 2), (:a, 1) ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)

        next!(source1, 1)
        next!(source2, 2)
        @test events == [ (:a, 1), (:b, 2), (:b, 2), (:a, 1) ]
        setpriority!(scheduler, :a)
        @test events == [ (:a, 1), (:b, 2), (:b, 2), (:a, 1) ]
        setpriority!(scheduler, :b)
        @test events == [ (:a, 1), (:b, 2), (:b, 2), (:a, 1) ]
    end

    @testset begin 
        scheduler = PriorityScheduler((:a, :b, :c))

        source1 = Subject(Int) 
        source2 = Subject(Int)
        source3 = Subject(Int)

        events = []

        subscription1 = subscribe!(source1 |> map(Tuple{Symbol, Int}, d -> (:a, d)) |> schedule_on(scheduler), (v) -> push!(events, v))
        subscription2 = subscribe!(source2 |> map(Tuple{Symbol, Int}, d -> (:b, d)) |> schedule_on(scheduler), (v) -> push!(events, v))
        subscription2 = subscribe!(source3 |> map(Tuple{Symbol, Int}, d -> (:c, d)) |> schedule_on(scheduler), (v) -> push!(events, v))

        @test events == [ ]
        
        next!(source1, 1)
        next!(source2, 2)
        next!(source2, 3)
        next!(source3, 4)
        next!(source3, 5)

        @test events == [ (:a, 1) ]
        release!(scheduler)
        @test events == [ (:a, 1), (:b, 2), (:b, 3), (:c, 4), (:c, 5) ]
    end
end

end

module RocketTimerObservableTest

using Test
using Rocket

@testset "TimerObservable" begin

    @testset begin
        @test timer(100, 100) == Rocket.TimerObservable{100, 100}()
    end

    @testset begin
        values      = Vector{Int}()
        errors      = Vector{Any}()
        completions = Vector{Int}()

        actor  = lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(errors, e),
            on_complete = ()  -> push!(completions, 0)
        )

        source = timer(100, 10) |> take(5)
        synced = sync(actor)

        subscribe!(source, synced)

        yield()

        wait(synced)

        @test values      == [ 0, 1, 2, 3, 4 ]
        @test errors      == [ ]
        @test completions == [ 0 ]
    end

    @testset begin
        values      = Vector{Int}()
        errors      = Vector{Any}()
        completions = Vector{Int}()

        actor  = lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(errors, e),
            on_complete = ()  -> push!(completions, 0)
        )

        source = timer(10) |> take(5)
        synced = sync(actor)

        subscribe!(source, synced)

        yield()

        wait(synced)

        @test values      == [ 0 ]
        @test errors      == [ ]
        @test completions == [ 0 ]
    end

end

end

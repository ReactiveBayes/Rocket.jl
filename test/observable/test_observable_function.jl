module RocketFunctionObservableTest

using Test
using Rocket

@testset "FunctionObservable" begin

    @testset begin
        source  = make(Int) do actor
            complete!(actor)
        end

        @test source isa FunctionObservable{Int}
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

        source = make(Int) do actor
            next!(actor, 1)
            next!(actor, 2)
            next!(actor, 3)
            setTimeout(1) do
                next!(actor, 4)
                complete!(actor)
            end
        end

        synced = sync(actor)

        subscribe!(source, synced)

        wait(synced)

        @test values      == [ 1, 2, 3, 4 ]
        @test errors      == [ ]
        @test completions == [ 0 ]
    end

end

end

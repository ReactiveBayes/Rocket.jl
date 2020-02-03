module RocketErrorObservableTest

using Test
using Rocket

@testset "ErrorObservable" begin

    @testset begin
        @test throwError(1)      == ErrorObservable{Any}(1)
        @test throwError(1, Int) == ErrorObservable{Int}(1)
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

        source = throwError(1, Int)

        subscribe!(source, actor)

        @test values      == [ ]
        @test errors      == [ 1 ]
        @test completions == [ ]
    end

end

end

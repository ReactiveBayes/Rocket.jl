module RxNeverObservableTest

using Test
using Rx

@testset "NeverObservable" begin

    @testset begin
        @test never()    == NeverObservable{Any}()
        @test never(Int) == NeverObservable{Int}()
    end

    @testset begin
        values      = Vector{Int}()
        errors      = Vector{Any}()
        completions = Vector{Int}()

        actor  = LambdaActor{Int}(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(errors, e),
            on_complete = ()  -> push!(completions, 0)
        )

        source = never(Int)

        subscribe!(source, actor)

        @test values      == [ ]
        @test errors      == [ ]
        @test completions == [ ]
    end

end

end

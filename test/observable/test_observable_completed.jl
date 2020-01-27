module RxCompleteObservableTest

using Test
using Rx

@testset "CompletedObservable" begin

    @testset begin
        @test completed()    == CompletedObservable{Any}()
        @test completed(Int) == CompletedObservable{Int}()
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

        source = completed(Int)

        subscribe!(source, actor)

        @test values      == [ ]
        @test errors      == [ ]
        @test completions == [ 0 ]
    end

end

end

module RxArrayObservableTest

using Test
using Rx

@testset "ArrayObservable" begin

    @testset begin
        @test from([ 1, 2, 3 ]) == ArrayObservable{Int}([ 1, 2, 3 ])
        @test from(( 1, 2, 3 )) == ArrayObservable{Int}([ 1, 2, 3 ])
        @test from(0)           == ArrayObservable{Int}([ 0 ])

        @test from([ 1.0, 2.0, 3.0 ]) == ArrayObservable{Float64}([ 1.0, 2.0, 3.0 ])
        @test from(( 1.0, 2.0, 3.0 )) == ArrayObservable{Float64}([ 1.0, 2.0, 3.0 ])
        @test from(0.0)               == ArrayObservable{Float64}([ 0.0 ])

        @test from("Hello!") == ArrayObservable{Char}([ 'H', 'e', 'l', 'l', 'o', '!' ])
        @test from('H')      == ArrayObservable{Char}([ 'H' ])
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

        source = from([ 1, 2, 3 ])

        subscribe!(source, actor)
        @test values      == [ 1, 2, 3 ]
        @test errors      == [ ]
        @test completions == [ 0 ]
    end

end

end

module RxArrayObservableTest

using Test

import Rx: LambdaActor, subscribe!
import Rx: ArrayObservable, on_subscribe!, from

@testset "ArrayObservable" begin

    @test from([ 1, 2, 3 ]) == ArrayObservable{Int}([ 1, 2, 3 ])
    @test from(( 1, 2, 3 )) == ArrayObservable{Int}([ 1, 2, 3 ])
    @test from(0)           == ArrayObservable{Int}([ 0 ])

    @test from([ 1.0, 2.0, 3.0 ]) == ArrayObservable{Float64}([ 1.0, 2.0, 3.0 ])
    @test from(( 1.0, 2.0, 3.0 )) == ArrayObservable{Float64}([ 1.0, 2.0, 3.0 ])
    @test from(0.0)               == ArrayObservable{Float64}([ 0.0 ])

    @test from("Hello!") == ArrayObservable{Char}([ 'H', 'e', 'l', 'l', 'o', '!' ])
    @test from('H')      == ArrayObservable{Char}([ 'H' ])

    values      = Vector{Int}()
    errors      = Vector{Any}()
    completions = Vector{Int}()

    actor  = LambdaActor{Int}(
        on_next     = (d) -> push!(values, d),
        on_error    = (e) -> push!(errors, e),
        on_complete = ()  -> push!(completions, 0)
    )
    source = from([ 1, 2, 3 ])

    subscribe!(source, actor)
    @test values      == [ 1, 2, 3 ]
    @test errors      == [ ]
    @test completions == [ 0 ]

    subscribe!(source |> map(Int, (d) -> d ^ 2), actor)
    @test values      == [ 1, 2, 3, 1, 4, 9 ]
    @test errors      == [ ]
    @test completions == [ 0, 0 ]

end

end

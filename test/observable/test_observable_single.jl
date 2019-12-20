module RxSingleObservableTest

using Test

import Rx: LambdaActor, subscribe!
import Rx: SingleObservable, on_subscribe!, of

@testset "SingleObservable" begin

    @test of(1)               == SingleObservable{Int}(1)
    @test of([ 1, 2, 3 ])     == SingleObservable{Vector{Int}}([ 1, 2, 3 ])
    @test of(( 1, 2, 3 ))     == SingleObservable{Tuple{Int, Int, Int}}(( 1, 2, 3 ))
    @test of("Hello, world!") == SingleObservable{String}("Hello, world!")
    @test of('H')             == SingleObservable{Char}('H')

    values      = Vector{Int}()
    errors      = Vector{Any}()
    completions = Vector{Int}()

    actor  = LambdaActor{Int}(
        on_next     = (d) -> push!(values, d),
        on_error    = (e) -> push!(errors, e),
        on_complete = ()  -> push!(completions, 0)
    )

    source = of(2)

    subscribe!(source, actor)

    @test values      == [ 2 ]
    @test errors      == [ ]
    @test completions == [ 0 ]

    subscribe!(source |> map(Int, (d) -> d ^ 2), actor)

    @test values      == [ 2, 4 ]
    @test errors      == [ ]
    @test completions == [ 0, 0 ]

end

end

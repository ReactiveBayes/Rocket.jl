module RxErrorObservableTest

using Test

import Rx: LambdaActor, subscribe!
import Rx: ErrorObservable, on_subscribe!, throwError

@testset "ErrorObservable" begin

    @test throwError(1)      == ErrorObservable{Any}(1)
    @test throwError(1, Int) == ErrorObservable{Int}(1)

    values      = Vector{Int}()
    errors      = Vector{Any}()
    completions = Vector{Int}()

    actor  = LambdaActor{Int}(
        on_next     = (d) -> push!(values, d),
        on_error    = (e) -> push!(errors, e),
        on_complete = ()  -> push!(completions, 0)
    )

    source = throwError(1, Int)

    subscribe!(source, actor)

    @test values      == [ ]
    @test errors      == [ 1 ]
    @test completions == [ ]

    subscribe!(source |> map(Int, (d) -> d ^ 2), actor)

    @test values      == [ ]
    @test errors      == [ 1, 1 ]
    @test completions == [ ]

end

end

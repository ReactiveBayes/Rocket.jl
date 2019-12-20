module RxNeverObservableTest

using Test

import Rx: LambdaActor, subscribe!
import Rx: NeverObservable, on_subscribe!, never

@testset "NeverObservable" begin

    @test never()    == NeverObservable{Any}()
    @test never(Int) == NeverObservable{Int}()

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

    subscribe!(source |> map(Int, (d) -> d ^ 2), actor)

    @test values      == [ ]
    @test errors      == [ ]
    @test completions == [ ]

end

end

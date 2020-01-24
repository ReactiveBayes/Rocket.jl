module RxLambdaActorTest

using Test

import Rx
import Rx: LambdaActor, next!, error!, complete!
import Rx: InconsistentSourceActorDataTypesError

@testset "LambdaActor" begin

    actor = LambdaActor{Int}(
        on_next     = (d) -> d + 1,
        on_error    = (e) -> e,
        on_complete = ()  -> "Lambda: completed"
    )

    # TODO
    # @test next!(actor, 1)        === 2
    # @test error!(actor, "error") === "error"
    # @test complete!(actor)       === "Lambda: completed"

    @test_throws InconsistentSourceActorDataTypesError{Int64,String} next!(actor, "string")
end

end

module RocketSkipErrorOperatorTest

using Test
using Rocket

@testset "operator: skip_error()" begin

    @testset begin
        source = throwError("error", Int) |> skip_error()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

end

end

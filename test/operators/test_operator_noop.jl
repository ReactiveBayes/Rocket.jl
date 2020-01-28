module RxNoopOperatorTest

using Test
using Rx

@testset "operator: noop()" begin

    @testset begin
        source = from(1:5)
        actor  = keep(Int)

        for i in 1:1000
            source = source |> map(Int, d -> d + 1) |> noop()
        end

        subscribe!(source, actor)

        @test actor.values == [ 1001, 1002, 1003, 1004, 1005 ]
    end

end

end

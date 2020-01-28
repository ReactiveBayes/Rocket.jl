module RxCountOperatorTest

using Test
using Rx

@testset "operator: count()" begin

    @testset begin
        source = from(1:42) |> count()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 42 ]
    end

    @testset begin
        source = completed(Int) |> count()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 0 ]
    end

end

end

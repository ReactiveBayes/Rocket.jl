module RxUppercaseOperatorTest

using Test
using Rx

@testset "operator: uppercase()" begin

    @testset begin
        source = from("Hello, world") |> uppercase()
        actor  = keep(Char)

        subscribe!(source, actor)

        @test actor.values == ['H', 'E', 'L', 'L', 'O', ',', ' ', 'W', 'O', 'R', 'L', 'D']
    end

end

end

module RxLowercaseOperatorTest

using Test
using Rx

@testset "lowercase()" begin

    @testset begin
        source = from("Hello, world") |> lowercase()
        actor  = keep(Char)

        subscribe!(source, actor)

        @test actor.values == ['h', 'e', 'l', 'l', 'o', ',', ' ', 'w', 'o', 'r', 'l', 'd']
    end

end

end

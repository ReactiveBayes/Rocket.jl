module RxDelayOperatorTest

using Test
using Rx

@testset "operator: delay()" begin

    @testset begin
        source = of(2) |> delay(10)
        actor  = keep(Int)
        synced = sync(actor)

        subscribe!(source, synced)

        elapsed = @elapsed wait(synced)

        @test elapsed > 0.02
    end

    @testset begin
        source = completed(Int) |> delay(10)
        actor  = keep(Int)
        synced = sync(actor)

        subscribe!(source, synced)

        elapsed = @elapsed wait(synced)

        @test elapsed < 0.02
    end

end

end

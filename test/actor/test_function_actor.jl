module RocketFunctionActorTest

using Test
using Rocket

@testset "FunctionActor" begin

    println("Testing: actor FunctionActor")

    @testset begin
        source = from_iterable([ 1, 2, 3 ])
        values = Int[]
        actor  = (t::Int) -> push!(values, t)

        subscribe!(source, actor)

        @test values == [ 1, 2, 3 ]
    end

    @testset begin
        source = faulted(Int, "Error")
        values = Int[]
        actor  = (t::Int) -> push!(values, t)

        @test_throws ErrorException subscribe!(source, actor)
        @test values == []
    end

end

end

module RocketBufferActorTest

using Test
using Rocket

@testset "BufferActor" begin

    println("Testing: actor BufferActor")

    @testset begin
        @test buffer(Int, 3) isa BufferActor{Int,Vector{Int}}
        @test buffer(Int, 3, 3) isa BufferActor{Int,Matrix{Int}}
    end

    @testset begin
        source = of([1, 2, 3])
        actor = buffer(Int, 3)

        subscribe!(source, actor)

        @test actor.values == [1, 2, 3]
        @test getvalues(actor) == [1, 2, 3]
    end

    @testset begin
        source = from([[1, 2, 3], [4, 5, 6]])
        actor = buffer(Int, 3)

        subscribe!(source, actor)

        @test actor.values == [4, 5, 6]
        @test getvalues(actor) == [4, 5, 6]
    end

    @testset begin
        source = faulted(Vector{Int}, "Error")
        actor = buffer(Int, 3)

        @test_throws ErrorException subscribe!(source, actor)
    end

    @testset begin
        source = of([1, 2, 3])
        actor = buffer(Int, 3)

        subscribe!(source, actor)

        @test actor[1] === 1
        @test actor[2] === 2
        @test actor[3] === 3

        @test collect(actor) == [1, 2, 3]
    end

    @testset begin
        source = of([1, 2, 3])
        actor = buffer(Int, 3)

        subscribe!(source, actor)

        i = 1
        for item in actor
            @test item === i
            i += 1
        end
    end

    @testset begin
        source = of([1, 2, 3])
        actor = buffer(Int, 3)

        subscribe!(source, actor)

        @test actor[1:end] == [1, 2, 3]
    end

    @testset begin
        source = of([1 2; 3 4])
        actor = buffer(Int, 2, 2)

        subscribe!(source, actor)

        @test actor.values == [1 2; 3 4]
        @test getvalues(actor) == [1 2; 3 4]
    end

    @testset begin
        source = of([4 5; 6 7])
        actor = buffer(Int, 2, 2)

        subscribe!(source, actor)

        @test actor.values == [4 5; 6 7]
        @test getvalues(actor) == [4 5; 6 7]
    end

    @testset begin
        source = faulted(Matrix{Int}, "Error")
        actor = buffer(Int, 2, 2)

        @test_throws ErrorException subscribe!(source, actor)
    end

    @testset begin
        source = of([1 2; 3 4])
        actor = buffer(Int, 2, 2)

        subscribe!(source, actor)

        @test actor[1] === 1
        @test actor[2] === 3
        @test actor[3] === 2
        @test actor[4] === 4

        @test actor[1, 1] === 1
        @test actor[1, 2] === 2
        @test actor[2, 1] === 3
        @test actor[2, 2] === 4

        @test collect(actor) == [1 2; 3 4]
    end

    @testset begin
        source = of([1 2; 3 4])
        actor = buffer(Int, 2, 2)

        subscribe!(source, actor)

        order = [1, 3, 2, 4]

        i = 1
        for item in actor
            @test item === order[i]
            i += 1
        end
    end

    @testset begin
        source = of([1 2; 3 4])
        actor = buffer(Int, 2, 2)

        subscribe!(source, actor)

        @test actor[1:end] == [1, 3, 2, 4]
    end
end

end

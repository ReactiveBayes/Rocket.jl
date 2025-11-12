module RocketListTest

using Test
using Rocket

import Rocket: List, pushnode!, remove

@testset "List" begin

    println("Testing: List")

    @testset begin
        list = List(Any)

        push!(list, 1)
        push!(list, 2.0)
        push!(list, "Hello")

        @test collect(list) == [1, 2.0, "Hello"]
    end

    @testset begin
        list = List(Int)

        @test_throws MethodError push!(list, 2.0)
        @test_throws MethodError push!(list, "Hello")
    end

    @testset begin
        list = List(Int)

        push!(list, 1)
        push!(list, 2)
        push!(list, 3)

        @test collect(list) == 1:3

        i = 1
        for item in list
            @test item === i
            i += 1
        end

        empty!(list)

        @test collect(list) == []

        empty!(list)

        @test collect(list) == []
    end

    @testset begin
        list = List(Int)

        n1 = pushnode!(list, 1)
        n2 = pushnode!(list, 2)
        n3 = pushnode!(list, 3)

        nodes = [n1, n2, n3]

        i = 1
        for item in list
            @test item === i
            @test collect(list) == i:3
            remove(nodes[i])
            @test collect(list) == (i+1):3
            i += 1
        end

        @test isempty(list)
    end

    @testset begin
        list = List(Int)

        n1 = pushnode!(list, 1)
        n2 = pushnode!(list, 2)
        n3 = pushnode!(list, 3)

        @test collect(list) == [1, 2, 3]

        remove(n1)

        @test collect(list) == [2, 3]

        remove(n2)

        @test collect(list) == [3]

        remove(n3)

        @test collect(list) == []
    end

    @testset begin
        list = List(Int)

        n1 = pushnode!(list, 1)
        n2 = pushnode!(list, 2)
        n3 = pushnode!(list, 3)

        @test collect(list) == [1, 2, 3]

        remove(n3)

        @test collect(list) == [1, 2]

        remove(n2)

        @test collect(list) == [1]

        remove(n1)

        @test collect(list) == []
    end

    @testset begin
        list = List(Int)

        n1 = pushnode!(list, 1)
        n2 = pushnode!(list, 2)
        n3 = pushnode!(list, 3)

        @test collect(list) == [1, 2, 3]

        remove(n2)

        @test collect(list) == [1, 3]

        remove(n1)

        @test collect(list) == [3]

        remove(n3)

        @test collect(list) == []
    end

    @testset begin
        list = List(Int)

        n1 = pushnode!(list, 1)
        n2 = pushnode!(list, 2)
        n3 = pushnode!(list, 3)

        @test collect(list) == [1, 2, 3]

        remove(n2)

        @test collect(list) == [1, 3]

        remove(n3)

        @test collect(list) == [1]

        remove(n1)

        @test collect(list) == []
    end

end

end

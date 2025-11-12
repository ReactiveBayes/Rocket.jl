module RocketIterableObservableTest

using Test
using Rocket

include("../test_helpers.jl")

import Base: iterate, length, eltype

@testset "IterableObservable" begin

    println("Testing: iterable")

    struct CustomEmptyIterable end

    Base.iterate(::CustomEmptyIterable) = nothing
    Base.length(::CustomEmptyIterable) = 0
    Base.eltype(::Type{<: CustomEmptyIterable}) = Int

    struct CustomSingleValueIterable end

    Base.iterate(::CustomSingleValueIterable) = (1, nothing)
    Base.iterate(::CustomSingleValueIterable, ::Nothing) = nothing
    Base.length(::CustomSingleValueIterable) = 1
    Base.eltype(::Type{<: CustomSingleValueIterable}) = Int

    @testset begin
        source = iterable([0])
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("IterableObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

    run_testset([
        (source = iterable([1, 2, 3]), values = @ts([1, 2, 3, c]), source_type = Int),
        (
            source = iterable("Hello!"),
            values = @ts(['H', 'e', 'l', 'l', 'o', '!', c]),
            source_type = Char,
        ),
        (source = iterable("H"), values = @ts(['H', c]), source_type = Char),
        (source = iterable((0, 1, 2)), values = @ts([0, 1, 2, c]), source_type = Int),
        (
            source = iterable((0, 1, 2), scheduler = AsyncScheduler(0)),
            values = @ts([0] ~ [1] ~ [2] ~ c),
            source_type = Int,
        ),
        (source = iterable(CustomEmptyIterable()), values = @ts(c), source_type = Int),
        (
            source = iterable(CustomSingleValueIterable()),
            values = @ts([1, c]),
            source_type = Int,
        ),
    ])

end

end

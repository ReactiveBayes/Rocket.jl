module RocketFileObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "SyncFileObservable" begin

    println("Testing: file")

    @testset "emits lines then completes" begin
        path, io = mktemp()
        write(io, "a\nb\nc\n")
        close(io)

        values = String[]
        completed = Ref(false)
        subscribe!(
            file(path),
            lambda(
                on_next = v -> push!(values, v),
                on_complete = () -> (completed[] = true),
            ),
        )

        @test values == ["a", "b", "c"]
        @test completed[] == true

        rm(path; force = true)
    end

    @testset "Issue #79: open failure is delivered via error!, not thrown" begin
        errored = Ref{Any}(nothing)
        completed = Ref(false)

        # must not throw out of subscribe!
        subscribe!(
            file(joinpath(mktempdir(), "does_not_exist_rocket.txt")),
            lambda(
                on_next = _ -> nothing,
                on_error = e -> (errored[] = e),
                on_complete = () -> (completed[] = true),
            ),
        )

        @test errored[] isa Exception
        @test completed[] == false
    end

end

end

module RocketLoggerActorTest

using Test
using Rocket

@testset "LoggerActor" begin

    @testset begin
        actor = logger(Int)

        @test !isempty(actor.name)
        @test actor.io === nothing
    end

    @testset begin
        buffer = IOBuffer()
        actor  = logger(Int, buffer)

        next!(actor, 1)

        output = String(take!(buffer))
        @test occursin("Data", output)
        @test occursin("1", output)

        next!(actor, 42)

        output = String(take!(buffer))
        @test occursin("Data", output)
        @test occursin("42", output)

        error!(actor, "err")

        output = String(take!(buffer))
        @test occursin("Error", output)
        @test occursin("err", output)

        complete!(actor)

        output = String(take!(buffer))
        @test occursin("Completed", output)

        @test_throws InconsistentSourceActorDataTypesError{Int64,String} next!(actor, "string")
    end

    @testset begin
        buffer = IOBuffer()
        actor  = logger(buffer, "CustomName")

        subscribe!(of(1), actor)
        output = String(take!(buffer))
        @test occursin("CustomName", output)
        @test occursin("Data", output)
        @test occursin("1", output)

        subscribe!(of(42), actor)
        output = String(take!(buffer))
        @test occursin("CustomName", output)
        @test occursin("Data", output)
        @test occursin("42", output)

        subscribe!(throwError("error"), actor)
        output = String(take!(buffer))
        @test occursin("CustomName", output)
        @test occursin("Error", output)
        @test occursin("error", output)

        subscribe!(completed(), actor)
        output = String(take!(buffer))
        @test occursin("CustomName", output)
        @test occursin("Completed", output)
    end

    @testset begin
        @test logger(Int) isa LoggerActor{Int, Nothing}
        @test logger()    isa Rocket.LoggerActorFactory{Nothing}
    end
end

end

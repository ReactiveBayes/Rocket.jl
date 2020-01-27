module RxLoggerActorTest

using Test
using Suppressor
using Rx

@testset "LoggerActor" begin

    @testset begin
        actor = LoggerActor{Int}("Logger")

        @test occursin("1", @capture_out next!(actor, 1))
        @test occursin("42", @capture_out next!(actor, 42))
        @test occursin("error", @capture_out error!(actor, "error"))
        @test occursin("Completed", @capture_out complete!(actor))

        @test_throws InconsistentSourceActorDataTypesError{Int64,String} next!(actor, "string")
    end

    @testset begin
        actor = logger()

        @test occursin("1", @capture_out subscribe!(of(1), actor))
        @test occursin("42", @capture_out subscribe!(of(42), actor))
        @test occursin("error", @capture_out subscribe!(throwError("error"), actor))
        @test occursin("Completed", @capture_out subscribe!(completed(), actor))
    end

    @testset begin
        @test logger(Int) isa LoggerActor{Int}
        @test logger()    isa Rx.LoggerActorFactory
    end
end

end

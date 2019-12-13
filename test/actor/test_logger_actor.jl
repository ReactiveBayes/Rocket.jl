module RxLoggerActorTest

using Test
using Suppressor

import Rx
import Rx: LoggerActor, next!, error!, complete!

@testset "LoggerActor" begin

    actor = LoggerActor{Int}("Logger")

    @test occursin("1", @capture_out next!(actor, 1))
    @test occursin("42", @capture_out next!(actor, 42))
    @test occursin("error", @capture_out error!(actor, "error"))
    @test occursin("Completed", @capture_out complete!(actor))

    @test_throws ErrorException next!(actor, "string")
end

end

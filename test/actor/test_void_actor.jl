module RxVoidActorTest

using Test
using Suppressor

import Rx
import Rx: VoidActor, next!, error!, complete!

@testset "VoidActor" begin

    actor = VoidActor{Int}()

    @test next!(actor,  1)       === nothing
    @test error!(actor, "error") === nothing
    @test complete!(actor)       === nothing

    @test isempty(@capture_out next!(actor, 0))
    @test isempty(@capture_out error!(actor, "some error"))
    @test isempty(@capture_out complete!(actor))

    @test_throws ErrorException next!(VoidActor{Int}, "string")
end

end

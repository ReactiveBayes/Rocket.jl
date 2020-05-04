module RocketTestActorTest

using Test
using Rocket

import Rocket: test_actor, check_isvalid, isreceived, iscompleted, isfailed, check_data_equals, check_error_equals

@testset "TestActor" begin

    println("Testing: TestActor")

    @testset begin
        actor = test_actor(Int)

        @test check_isvalid(actor)
    end

    @testset begin
        actor1 = test_actor(Any)
        actor2 = test_actor(Any)

        push!(Rocket.data(actor1), Rocket.ErrorTestEvent("err"))
        push!(Rocket.data(actor2), Rocket.CompleteTestEvent())

        @test_throws Rocket.DataEventIncorrectTypeException check_isvalid(actor1)
        @test_throws Rocket.DataEventIncorrectTypeException check_isvalid(actor2)
    end

    @testset begin
        actor1 = test_actor(Any)
        actor2 = test_actor(Any)

        push!(Rocket.errors(actor1), Rocket.DataTestEvent("data"))
        push!(Rocket.errors(actor2), Rocket.CompleteTestEvent())

        @test_throws Rocket.ErrorEventIncorrectTypeException check_isvalid(actor1)
        @test_throws Rocket.ErrorEventIncorrectTypeException check_isvalid(actor2)
    end

    @testset begin
        actor1 = test_actor(Any)
        actor2 = test_actor(Any)

        push!(Rocket.completes(actor1), Rocket.DataTestEvent("data"))
        push!(Rocket.completes(actor2), Rocket.ErrorTestEvent("err"))

        @test_throws Rocket.CompleteEventIncorrectTypeException check_isvalid(actor1)
        @test_throws Rocket.CompleteEventIncorrectTypeException check_isvalid(actor2)
    end

    @testset begin
        actor = test_actor(Any)

        d1 = Rocket.DataTestEvent(0)
        d2 = Rocket.DataTestEvent(0)

        push!(Rocket.data(actor), d2)
        push!(Rocket.data(actor), d1)

        @test_throws Rocket.DataEventIncorrectTimestampsOrderException check_isvalid(actor)
    end

    @testset begin
        actor = test_actor(Any)

        error!(actor, "error1")
        error!(actor, "error2")

        @test_throws Rocket.MultipleErrorEventsException check_isvalid(actor)
    end

    @testset begin
        actor = test_actor(Any)

        complete!(actor)
        complete!(actor)

        @test_throws Rocket.MultipleCompleteEventsException check_isvalid(actor)
    end

    @testset begin
        actor = test_actor(Any)

        complete!(actor)
        error!(actor, "error")

        @test_throws Rocket.ErrorAfterCompleteEventException check_isvalid(actor)
    end

    @testset begin
        actor = test_actor(Any)

        error!(actor, "error")
        complete!(actor)

        @test_throws Rocket.CompleteAfterErrorEventException check_isvalid(actor)
    end

    @testset begin
        actor = test_actor(Any)

        error!(actor, "error")
        next!(actor, 0)

        @test_throws Rocket.NextAfterErrorEventException check_isvalid(actor)
    end

    @testset begin
        actor = test_actor(Any)

        complete!(actor)
        next!(actor, 0)

        @test_throws Rocket.NextAfterCompleteEventException check_isvalid(actor)
    end

    @testset begin
        actor = test_actor(Int)

        next!(actor, "string")

        @test_throws Rocket.UnacceptableNextEventDataTypeException check_isvalid(actor)
    end

    @testset begin
        actor1 = test_actor(Int)

        next!(actor1, 0)
        next!(actor1, 1)
        next!(actor1, 2)
        complete!(actor1)

        @test check_isvalid(actor1)
        @test isreceived(actor1)
        @test iscompleted(actor1)
        @test !isfailed(actor1)
        @test check_data_equals(actor1, [ 0, 1, 2 ])

        actor2 = test_actor(String)

        next!(actor2, "0")
        next!(actor2, "1")
        next!(actor2, "2")
        error!(actor2, "error")

        @test check_isvalid(actor2)
        @test isreceived(actor2)
        @test !iscompleted(actor2)
        @test isfailed(actor2)
        @test check_data_equals(actor2, [ "0", "1", "2" ])
        @test check_error_equals(actor2, "error")

        actor3 = test_actor(Union{Int, String})

        next!(actor3, 0)
        next!(actor3, "1")
        next!(actor3, "2")
        next!(actor3, 3)

        @test check_isvalid(actor3)
        @test isreceived(actor3)
        @test !iscompleted(actor3)
        @test !isfailed(actor3)
        @test check_data_equals(actor3, [ 0, "1", "2", 3 ])

        actor4 = test_actor(Any)

        @test check_isvalid(actor4)
        @test !isreceived(actor4)
        @test !iscompleted(actor4)
        @test !isfailed(actor4)
        @test check_data_equals(actor4, [ ])

        actor5 = test_actor(Any)

        next!(actor5, rand())

        @test_throws Rocket.DataEventsEqualityFailedException check_data_equals(actor5, [ rand() ])

        actor6 = test_actor(Any)

        error!(actor6, rand())

        @test_throws Rocket.ErrorEventEqualityFailedException check_error_equals(actor6, rand())
    end

    @testset begin
        @test test_actor(Int) isa Rocket.TestActor
        @test test_actor()    isa Rocket.TestActorFactory
    end
end

end

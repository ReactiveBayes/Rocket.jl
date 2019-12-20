module RxTeardownTest

using Test

import Rx
import Rx: TeardownLogic, UnsubscribableTeardownLogic, CallableTeardownLogic, VoidTeardownLogic, UndefinedTeardownLogic
import Rx: Teardown, as_teardown
import Rx: unsubscribe!, teardown!, on_unsubscribe!

import Rx: UndefinedTeardownLogicTraitUsageError, MissingOnUnsubscribeImplementationError

@testset "Teardown" begin

    struct DummyType end

    struct AnotherDummyType end
    Rx.as_teardown(::Type{<:AnotherDummyType}) = VoidTeardownLogic()

    struct DummySubscription end
    Rx.as_teardown(::Type{<:DummySubscription}) = UnsubscribableTeardownLogic()

    struct ImplementedSubscription end
    Rx.as_teardown(::Type{<:ImplementedSubscription}) = UnsubscribableTeardownLogic()
    Rx.on_unsubscribe!(::ImplementedSubscription)     = "unsubscribed"

    @testset "as_teardown" begin
        # Check if arbitrary dummy type has undefined teardown logic
        @test as_teardown(DummyType) === UndefinedTeardownLogic()

        # Check if as_teardown returns specified teardown logic
        @test as_teardown(AnotherDummyType) === VoidTeardownLogic()
        @test as_teardown(DummySubscription) === UnsubscribableTeardownLogic()
        @test as_teardown(ImplementedSubscription) === UnsubscribableTeardownLogic()

        # Check if as_teardown returns CallableTeardownLogic for Function object
        @test as_teardown(Function) === CallableTeardownLogic()
    end

    @testset "unsubscribe!" begin
        # Check if arbitrary dummy type throws an error in unsubscribe!
        @test_throws UndefinedTeardownLogicTraitUsageError unsubscribe!(DummyType())

        # Check if void teardown object does nothing
        @test unsubscribe!(AnotherDummyType()) === nothing

        # Check if function object calls itself in unsubscribe!
        @test unsubscribe!(() -> return 1) === 1

        #Check if dummy subscription throws an error in unusubscribe!
        @test_throws MissingOnUnsubscribeImplementationError unsubscribe!(DummySubscription())

        #Check if implemented subscription calls on_unsubscribe!
        @test unsubscribe!(ImplementedSubscription()) === "unsubscribed"
    end

end

end

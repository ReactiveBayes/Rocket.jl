module RocketTeardownTest

using Test

import Rocket
import Rocket:
    TeardownLogic,
    UnsubscribableTeardownLogic,
    CallableTeardownLogic,
    VoidTeardownLogic,
    InvalidTeardownLogic
import Rocket: Teardown, as_teardown
import Rocket: unsubscribe!, teardown!, on_unsubscribe!

import Rocket:
    InvalidTeardownLogicTraitUsageError,
    InvalidMultipleTeardownLogicTraitUsageError,
    MissingOnUnsubscribeImplementationError

@testset "Teardown" begin

    struct DummyType end

    struct AnotherDummyType end
    Rocket.as_teardown(::Type{<:AnotherDummyType}) = VoidTeardownLogic()

    struct DummySubscription end
    Rocket.as_teardown(::Type{<:DummySubscription}) = UnsubscribableTeardownLogic()

    struct ImplementedSubscription end
    Rocket.as_teardown(::Type{<:ImplementedSubscription}) = UnsubscribableTeardownLogic()
    Rocket.on_unsubscribe!(::ImplementedSubscription) = "unsubscribed"

    @testset "as_teardown" begin
        # Check if arbitrary dummy type has undefined teardown logic
        @test as_teardown(DummyType) === InvalidTeardownLogic()

        # Check if as_teardown returns specified teardown logic
        @test as_teardown(AnotherDummyType) === VoidTeardownLogic()
        @test as_teardown(DummySubscription) === UnsubscribableTeardownLogic()
        @test as_teardown(ImplementedSubscription) === UnsubscribableTeardownLogic()

        # Check if as_teardown returns CallableTeardownLogic for Function object
        @test as_teardown(Function) === CallableTeardownLogic()
    end

    @testset "unsubscribe!" begin
        # Check if arbitrary dummy type throws an error in unsubscribe!
        @test_throws InvalidTeardownLogicTraitUsageError unsubscribe!(DummyType())

        # Check if void teardown object does nothing
        @test unsubscribe!(AnotherDummyType()) === nothing

        # Check if function object calls itself in unsubscribe!
        @test unsubscribe!(() -> return 1) === 1

        #Check if dummy subscription throws an error in unusubscribe!
        @test_throws MissingOnUnsubscribeImplementationError unsubscribe!(
            DummySubscription(),
        )

        #Check if implemented subscription calls on_unsubscribe!
        @test unsubscribe!(ImplementedSubscription()) === "unsubscribed"
    end

    @testset "multiple unsubscribe!" begin
        # Check if arbitrary dummy type throws an error in unsubscribe!
        @test_throws InvalidMultipleTeardownLogicTraitUsageError unsubscribe!((
            DummyType(),
            ImplementedSubscription(),
        ))
        @test_throws InvalidMultipleTeardownLogicTraitUsageError unsubscribe!((
            ImplementedSubscription(),
            DummyType(),
        ))
        @test_throws InvalidMultipleTeardownLogicTraitUsageError unsubscribe!([
            DummyType(),
            ImplementedSubscription(),
        ])
        @test_throws InvalidMultipleTeardownLogicTraitUsageError unsubscribe!([
            ImplementedSubscription(),
            DummyType(),
        ])

        #Check if implemented subscription calls on_unsubscribe!
        @test unsubscribe!((ImplementedSubscription(), ImplementedSubscription())) ===
              nothing
        @test unsubscribe!((ImplementedSubscription(), AnotherDummyType())) === nothing
        @test unsubscribe!((AnotherDummyType(), ImplementedSubscription())) === nothing
        @test unsubscribe!((AnotherDummyType(), AnotherDummyType())) === nothing

        @test unsubscribe!([ImplementedSubscription(), ImplementedSubscription()]) ===
              nothing
        @test unsubscribe!([ImplementedSubscription(), AnotherDummyType()]) === nothing
        @test unsubscribe!([AnotherDummyType(), ImplementedSubscription()]) === nothing
        @test unsubscribe!([AnotherDummyType(), AnotherDummyType()]) === nothing
    end

end

end

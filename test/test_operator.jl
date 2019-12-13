module RxOperatorTest

using Test

import Rx
import Rx: OperatorTrait, ValidOperator, InvalidOperator
import Rx: Operator, as_operator, call_operator!
import Rx: |>

@testset "Operator" begin

    struct DummyType end

    struct NotImplementedOperator <: Operator{Int, String} end

    struct ExplicitlyDefinedOperator end
    Rx.as_operator(::Type{<:ExplicitlyDefinedOperator}) = ValidOperator{String, Int}()

    struct IdentityIntOperator <: Operator{Int, Int} end
    Rx.on_call!(operator::IdentityIntOperator, source) = source

    struct SomeSubscribable{D} <: Rx.Subscribable{D} end

    @testset "as_operator" begin
        # Check if arbitrary dummy type has not valid operator type
        @test as_operator(DummyType) === InvalidOperator()

        # Check if as_operator returns valid operator type for subtypes of Operator abstract type
        @test as_operator(NotImplementedOperator) === ValidOperator{Int, String}()

        # Check if as_operator returns valid operator type for explicitly defined types
        @test as_operator(ExplicitlyDefinedOperator) === ValidOperator{String, Int}()
    end

    @testset "|>" begin
        int_source    = SomeSubscribable{Int}()
        string_source = SomeSubscribable{String}()

        # Check if pipe operator throws an error for invalid operator type
        @test_throws ErrorException int_source |> DummyType()

        # Check if pipe operator throws an error for invalid source and operator data types
        @test_throws ErrorException string_source |> IdentityIntOperator()

        # Check if pipe operator throws an error for not implemented operator
        @test_throws ErrorException int_source    |> NotImplementedOperator()
        @test_throws ErrorException string_source |> ExplicitlyDefinedOperator()

        # Check if pipe operator calls on_call! for valid operator
        @test int_source |> IdentityIntOperator() === int_source
    end

end

end

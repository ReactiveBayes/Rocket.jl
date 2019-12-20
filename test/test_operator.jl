module RxOperatorTest

using Test

import Rx
import Rx: OperatorTrait, TypedOperatorTrait, LeftTypedOperatorTrait, RightTypedOperatorTrait, InferableOperatorTrait, InvalidOperatorTrait
import Rx: AbstractOperator, TypedOperator, LeftTypedOperator, RightTypedOperator, InferableOperator
import Rx: as_operator, call_operator!, on_call!, operator_right
import Rx: |>

@testset "Operator" begin

    struct DummyType end

    struct NotImplementedOperator <: TypedOperator{Int, String} end

    struct ExplicitlyDefinedOperator end
    Rx.as_operator(::Type{<:ExplicitlyDefinedOperator}) = TypedOperatorTrait{String, Int}()

    struct IdentityIntOperator <: TypedOperator{Int, Int} end
    Rx.on_call!(::Type{Int}, ::Type{Int}, operator::IdentityIntOperator, source) = source

    struct LeftTypedStringIdentityOperator <: LeftTypedOperator{String} end
    Rx.on_call!(::Type{String}, ::Type{String}, operator::LeftTypedStringIdentityOperator, source) = source
    Rx.operator_right(::LeftTypedStringIdentityOperator, ::Type{String}) = String

    struct LeftTypedIntIdentityNotImplementedOperator <: LeftTypedOperator{Int} end
    Rx.on_call!(::Type{Int}, ::Type{Int}, operator::LeftTypedIntIdentityNotImplementedOperator, source) = source
    # Should be commented as we are testing this case
    # Rx.operator_right(::LeftTypedIntIdentityNotImplementedOperator, ::Type{Int}) = Int

    struct RightTypedFloatZeroOperator <: RightTypedOperator{Float64} end
    Rx.on_call!(::Type{L}, ::Type{Float64}, operator::RightTypedFloatZeroOperator, source) where L = Rx.from([ 0.0 ])

    struct InferableIntoZeroTupleOperator <: InferableOperator end
    Rx.on_call!(::Type{L}, ::Type{Tuple{L, L}}, operator::InferableIntoZeroTupleOperator, source) where L = Rx.from([ (zero(L), zero(L)) ])
    Rx.operator_right(::InferableIntoZeroTupleOperator, ::Type{L}) where L = Tuple{L, L}

    struct InferableNotImplementedOperator <: InferableOperator end
    Rx.on_call!(::Type{L}, ::Type{L}, operator::InferableIntoZeroTupleOperator, source) where L = source
    # Should be commented as we are testing this case
    # Rx.operator_right(::InferableNotImplementedOperator, ::Type{L}) where L = L

    struct SomeSubscribable{D} <: Rx.Subscribable{D} end

    @testset "as_operator" begin
        # Check if arbitrary dummy type has not valid operator type
        @test as_operator(DummyType) === InvalidOperatorTrait()

        # Check if as_operator returns valid operator type for subtypes of Operator abstract type
        @test as_operator(NotImplementedOperator)          === TypedOperatorTrait{Int, String}()
        @test as_operator(LeftTypedStringIdentityOperator) === LeftTypedOperatorTrait{String}()
        @test as_operator(RightTypedFloatZeroOperator)     === RightTypedOperatorTrait{Float64}()
        @test as_operator(InferableIntoZeroTupleOperator)  === InferableOperatorTrait()

        # Check if as_operator returns valid operator type for explicitly defined types
        @test as_operator(ExplicitlyDefinedOperator) === TypedOperatorTrait{String, Int}()
    end

    @testset "|>" begin
        int_source    = SomeSubscribable{Int}()
        string_source = SomeSubscribable{String}()
        float_source  = SomeSubscribable{Float64}()

        # Check if pipe operator throws an error for invalid operator type
        @test_throws MethodError int_source |> DummyType()

        # Check if pipe operator throws an error for invalid source and operator data types
        @test_throws ErrorException string_source |> IdentityIntOperator()
        @test_throws ErrorException int_source    |> LeftTypedStringIdentityOperator()

        # Check if pipe operator throws an error for not implemented operator
        @test_throws MethodError string_source |> ExplicitlyDefinedOperator()
        @test_throws ErrorException int_source    |> NotImplementedOperator()
        @test_throws ErrorException int_source    |> LeftTypedIntIdentityNotImplementedOperator()
        @test_throws ErrorException int_source    |> InferableNotImplementedOperator()

        # Check if pipe operator calls on_call! for valid operator
        @test int_source |> IdentityIntOperator() === int_source

        # Check if right typed operator may operate on different input source types
        @test int_source    |> RightTypedFloatZeroOperator() == Rx.from([ 0.0 ])
        @test string_source |> RightTypedFloatZeroOperator() == Rx.from([ 0.0 ])

        # Check if inferrable operator may operate on different input source types
        @test int_source    |> InferableIntoZeroTupleOperator() == Rx.from([ (0, 0) ])
        @test float_source  |> InferableIntoZeroTupleOperator() == Rx.from([ (0.0, 0.0) ])
    end

end

end

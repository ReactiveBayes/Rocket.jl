# Utility helpers for testing operators
export run_testset

using Rocket
using Test

const TESTSET_SYNC_MAXIMUM_TIMEOUT = 60000 # 60 sec

make_test_actor(::Type{T}) where T = sync(test_actor(T), timeout = TESTSET_SYNC_MAXIMUM_TIMEOUT)

# [ WIP ]
# function testset_parameters(tuple::NamedTuple{V, T}) where { V, T <: Tuple }
#     parameters = Dict([
#         (:source, nothing),
#         (:values, []),
#         (:is_completed, true),
#         (:is_failed, false),
#         (:error, nothing),
#         (:wait_for, TESTSET_SYNC_MAXIMUM_TIMEOUT),
#     ])
#
#     for key in V
#         parameters[key] = tuple[key]
#     end
#
#     return parameters
# end

function test(testset::NamedTuple{(:source, :values), Tuple{ S, V }}) where { L, T <: L, S <: Subscribable{T}, V <: Vector{L} }
    actor = make_test_actor(T)

    subscribe!(testset[:source], actor)

    wait(actor)

    @test check_isvalid(actor.actor)
    @test iscompleted(actor.actor)
    @test !isfailed(actor.actor)
    @test check_data_equals(actor.actor, testset[:values])

    return true
end

function test(testset::NamedTuple{(:source, :values, :is_completed, :wait_for), Tuple{ S, V, Bool, Int }}) where { L, T <: L, S <: Subscribable{T}, V <: Vector{L} }
    if testset[:is_completed] === true
        test((source = testset[:source], values = source = testset[:values]))
    else
        actor = make_test_actor(T)

        subscribe!(testset[:source], actor)

        sleep(testset[:wait_for] / MILLISECONDS_IN_SECOND)

        @test check_isvalid(actor.actor)
        @test !iscompleted(actor.actor)
        @test !isfailed(actor.actor)
        @test check_data_equals(actor.actor, testset[:values])

        return true
    end
end

function test(testset::NamedTuple{(:source, :values, :is_failed, :error), Tuple{ S, V, Bool, E }}) where { L, T <: L, S <: Subscribable{T}, V <: Vector{L}, E }
    if testset[:is_failed] === false
        test((source = testset[:source], values = testset[:values]))
    else
        actor = make_test_actor(T)

        subscribe!(testset[:source], actor)

        wait(actor)

        @test check_isvalid(actor.actor)
        @test !iscompleted(actor.actor)
        @test isfailed(actor.actor)
        @test check_data_equals(actor.actor, testset[:values])
        @test check_error_equals(actor.actor, testset[:error])

        return true
    end
end

function run_testset(testsets)
    for ts in testsets
        @testset begin
            test(ts)
        end
    end
end

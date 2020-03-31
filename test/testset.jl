# Utility helpers for testing operators
export AbstractTestset, test

using Test

const TESTSET_SYNC_MAXIMUM_TIMEOUT = 60000 # 60 sec

abstract type AbstractTestset end

struct IncompletedTestset{T, S}
    source :: S
    values :: Vector{T, S}
end

struct CompletedTestset{T, S}
    source :: S
    values :: Vector{T}
end

make_test_actor(::Type{T}) where T = sync(test_actor(T), timeout = TESTSET_SYNC_MAXIMUM_TIMEOUT)

function test(testset::CompletedTestset{T}) where T
    actor = make_test_actor(T)

    subscribe!(testset.source, actor)

    wait(actor)

    @test check_isvalid(actor.actor)
    @test iscompleted(actor.actor)
    @test !isfailed(actor.actor)
    @test check_data_equals(actor.actor, values)
end

# Utility helpers for testing operators
export run_testset, run_proxyshowcheck, @ts

using Rocket
using Test

import Rocket: test_on_source
import Rocket: @ts

const TESTSET_MAXIMUM_TIMEOUT = 5000 # 5 sec
const TESTSET_MAXIMUM_COMPILATION_TIMEOUT = 5000 # 5 sec

# ------------------------------------------------- #
# Helpers for running custom testsets for operators
# ------------------------------------------------- #

function testset_parameters(testset::NamedTuple{V, T}) where { V, T <: Tuple }
    parameters = Dict([
        (:source, nothing),
        (:values, nothing),
        (:wait_for, TESTSET_MAXIMUM_TIMEOUT),
        (:throws, nothing),
        (:source_type, Any)
    ])

    for key in V
        parameters[key] = testset[key]
    end

    return parameters
end

function test(testset, check_timings)
    parameters = testset_parameters(testset)

    # Force JIT compilation of all statements before actual test execution
    # Iffy approach, TODO
    try
        test_on_source(parameters[:source], parameters[:values]; maximum_wait = convert(Float64, TESTSET_MAXIMUM_COMPILATION_TIMEOUT), check_timings = false)
    catch _
    end

    if parameters[:source] === nothing
        error("Missing :source field in the testset")
    elseif parameters[:throws] !== nothing
        @test_throws parameters[:throws] test_on_source(parameters[:source], parameters[:values]; maximum_wait = parameters[:wait_for], check_timings = check_timings)
    else
        @test test_on_source(parameters[:source], parameters[:values]; maximum_wait = convert(Float64, parameters[:wait_for]), check_timings = check_timings)
    end

    if parameters[:source_type] !== Any
        @test eltype(parameters[:source]) === parameters[:source_type]
    end

    return true
end

function run_testset(testsets; check_timings = true)
    for ts in testsets
        @testset begin
            test(ts, check_timings)
        end
    end
end

# Utility helpers for testing operators
export run_testset, @ts

using Rocket
using Test

import Rocket: test_on_source
import Rocket: @ts

const TESTSET_MAXIMUM_TIMEOUT = 5000 # 5 sec
const TESTSET_MAXIMUM_COMPILATION_TIMEOUT = 5000 # 5 sec

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

function test(testset)
    parameters = testset_parameters(testset)

    # Force JIT compilation of all statements before actual test execution
    # Iffy approach, TODO
    try
        test_on_source(parameters[:source], parameters[:values]; maximum_wait = convert(Float64, TESTSET_MAXIMUM_COMPILATION_TIMEOUT))
    catch _
    end

    if parameters[:source] === nothing
        error("Missing :source field in the testset")
    elseif parameters[:throws] !== nothing
        @test_throws parameters[:throws] test_on_source(parameters[:source], parameters[:values]; maximum_wait = parameters[:wait_for])
    else
        @test test_on_source(parameters[:source], parameters[:values]; maximum_wait = convert(Float64, parameters[:wait_for]))
    end

    if parameters[:source_type] !== Any
        @test subscribable_extract_type(parameters[:source]) === parameters[:source_type]
    end

    return true
end

function run_testset(testsets)
    for ts in testsets
        @testset begin
            test(ts)
        end
    end
end

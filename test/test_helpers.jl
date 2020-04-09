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

# --------------------------------------------------- #
# Helpers for checking Base.show methods for operators
# --------------------------------------------------- #

function run_proxyshowcheck(name::String, operator; args::Union{NamedTuple{V, T}, Nothing} = nothing) where { V, T <: Tuple }

    parameters = Dict([
        (:custom_source, never(Any)),
        (:custom_actor,  void(Any)),
        (:check_operator, true),
        (:check_proxy, true),
        (:check_actor, :auto),
        (:check_observable, :auto),
        (:check_subscription, false)
    ])

    if args !== nothing
        for key in V
            parameters[key] = args[key]
        end
    end

    withoperator = parameters[:custom_source] |> operator

    if !(withoperator isa ProxyObservable)
        error("run_proxyshowcheck(...) is a helper function only for proxy-based operators")
    end

    proxytrait = Rocket.as_proxy(typeof(withoperator))

    @testset "Check Base.show for $name operator" begin
        io = IOBuffer()

        if parameters[:check_operator] === true
            show(io, operator)
            printed = String(take!(io))
            if !occursin("$(name)Operator", printed)
                error("Check for Base.show(io, operator::$(typeof(operator)) has failed")
            end
        end

        if parameters[:check_proxy] === true
            show(io, withoperator.proxy)
            printed = String(take!(io))
            if !occursin("$(name)Proxy", printed)
                error("Check for Base.show(io, proxy::$(typeof(withoperator.proxy)) has failed")
            end
        end

        if parameters[:check_actor] === true || (parameters[:check_actor] === :auto && (proxytrait isa Rocket.ValidActorProxy || proxytrait isa Rocket.ValidActorSourceProxy))
            actor = Rocket.actor_proxy!(withoperator.proxy, parameters[:custom_actor])
            show(io, actor)
            printed = String(take!(io))
            if !occursin("$(name)Actor", printed)
                error("Check for Base.show(io, actor::$(typeof(actor)) has failed")
            end
        end

        if parameters[:check_observable] === true || (parameters[:check_observable] === :auto && (proxytrait isa Rocket.ValidSourceProxy || proxytrait isa Rocket.ValidActorSourceProxy))
            source = Rocket.source_proxy!(withoperator.proxy, parameters[:custom_source])
            show(io, source)
            printed = String(take!(io))
            if !occursin("$(name)Observable", printed)
                error("Check for Base.show(io, observable::$(typeof(source)) has failed")
            end
        end

        if parameters[:check_subscription] === true
            subscription = subscribe!(withoperator, parameters[:custom_actor])
            show(io, subscription)
            printed = String(take!(io))
            if !occursin("$(name)Subscription", printed)
                error("Check for Base.show(io, subscription::$(typeof(subscription)) has failed")
            end
            unsubscribe!(subscription)
        else
            subscription = subscribe!(withoperator, parameters[:custom_actor])
            show(io, subscription)
            printed = String(take!(io))
            if occursin("$(name)", printed)
                error("Check for Base.show(io, subscription::$(typeof(subscription)) has failed")
            end
            unsubscribe!(subscription)
        end

        @test true
    end

end

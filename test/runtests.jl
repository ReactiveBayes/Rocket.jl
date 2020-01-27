module RxTest

using Test, Documenter, Rx

doctest(Rx)

@testset "Rx" begin

    include("./test_teardown.jl")
    include("./teardown/test_void_teardown.jl")
    include("./teardown/test_chain_teardown.jl")

    include("./test_actor.jl")
    include("./actor/test_void_actor.jl")
    include("./actor/test_lambda_actor.jl")
    include("./actor/test_logger_actor.jl")
    include("./actor/test_keep_actor.jl")
    include("./actor/test_sync_actor.jl")

    include("./test_subscribable.jl")
    include("./observable/test_observable_function.jl")
    include("./observable/test_observable_single.jl")
    include("./observable/test_observable_array.jl")
    include("./observable/test_observable_error.jl")
    include("./observable/test_observable_never.jl")
    include("./observable/test_observable_completed.jl")
    include("./observable/test_observable_timer.jl")
    include("./observable/test_observable_interval.jl")


    include("./test_operator.jl")
    include("./operators/test_catch_error.jl")
end

end

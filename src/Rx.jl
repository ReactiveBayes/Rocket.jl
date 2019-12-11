module Rx

include("teardown.jl")
include("teardown/void.jl")

include("actor.jl")
include("actor/lambda.jl")

include("subscribable.jl")

include("observable/array.jl")
include("observable/error.jl")
include("observable/proxy.jl")

include("operator.jl")
include("operators/map.jl")
include("operators/filter.jl")

end # module

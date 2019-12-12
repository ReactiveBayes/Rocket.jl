module Rx

include("teardown.jl")
include("teardown/void.jl")

include("actor.jl")
include("actor/lambda.jl")
include("actor/logger.jl")

include("subscribable.jl")

include("observable/array.jl")
include("observable/error.jl")
include("observable/proxy.jl")
include("observable/subject.jl")

include("operator.jl")
include("operators/map.jl")
include("operators/filter.jl")
include("operators/count.jl")
include("operators/enumerate.jl")
include("operators/take.jl")
include("operators/tap.jl")

end # module

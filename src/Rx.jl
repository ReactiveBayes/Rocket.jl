module Rx

include("teardown.jl")
include("teardown/void.jl")
include("teardown/chain.jl")

include("actor.jl")
include("actor/lambda.jl")
include("actor/logger.jl")
include("actor/void.jl")
include("actor/async.jl")

include("subscribable.jl")

include("observable/array.jl")
include("observable/error.jl")
include("observable/proxy.jl")
include("observable/subject.jl")

include("operator.jl")
include("operators/map.jl")
include("operators/reduce.jl")
include("operators/scan.jl")
include("operators/filter.jl")
include("operators/count.jl")
include("operators/enumerate.jl")
include("operators/take.jl")
include("operators/first.jl")
include("operators/last.jl")
include("operators/tap.jl")
include("operators/sum.jl")
include("operators/max.jl")
include("operators/min.jl")

end # module

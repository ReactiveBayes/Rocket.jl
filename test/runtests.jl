module RxTest

using Test

@testset "Rx" begin
    include("./test_teardown.jl")
    include("./teardown/test_void_teardown.jl")
    include("./teardown/test_chain_teardown.jl")

    include("./test_actor.jl")
end

end

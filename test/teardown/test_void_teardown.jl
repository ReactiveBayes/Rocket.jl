module RxTeardownVoidTest

using Test

import Rx
import Rx: Teardown, VoidTeardown

@testset "VoidTeardown" begin

    @test VoidTeardown() isa Teardown
    @test Rx.as_teardown(VoidTeardown) === Rx.VoidTeardownLogic()
    @test Rx.unsubscribe!(VoidTeardown()) === nothing

end

end

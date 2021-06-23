module RocketHelpersUpdatesTest

using Test
using Rocket

import Rocket: GenericUpdatesStatus, UInt8UpdatesStatus, getustorage
import Rocket: cstatus, vstatus, ustatus, cstatus!, vstatus!, ustatus!
import Rocket: fill_cstatus!, fill_vstatus!, fill_ustatus!, all_cstatus, all_vstatus, all_ustatus

@testset "Helpers Updates" begin

    println("Testing: updates")

    @testset begin
        for i in 9:100
            T = typeof(ntuple(_ -> 1, i))
            u = getustorage(T)
            @test typeof(u) <: GenericUpdatesStatus
        end
    end

    @testset begin
        for i in 1:8
            T = typeof(ntuple(_ -> 1, i))
            u = getustorage(T)
            @test typeof(u) <: UInt8UpdatesStatus
        end
    end

    @testset begin
        for n in 1:12
            T = typeof(ntuple(_ -> 1, n))
            u = getustorage(T)
            
            for i in 1:n
                for _ in 1:2
                    cstatus!(u, i, true)
                    @test cstatus(u, i) === true
                    cstatus!(u, i, false)
                    @test cstatus(u, i) === false
                    vstatus!(u, i, true)
                    @test vstatus(u, i) === true
                    vstatus!(u, i, false)
                    @test vstatus(u, i) === false
                    ustatus!(u, i, true)
                    @test ustatus(u, i) === true
                    ustatus!(u, i, false)
                    @test ustatus(u, i) === false

                    fill_cstatus!(u, true)
                    @test all_cstatus(u) === true
                    for k in 1:n
                        @test cstatus(u, k) === true
                    end
                    cstatus!(u, i, false)
                    @test all_cstatus(u) === false
                    fill_cstatus!(u, false)
                    @test all_cstatus(u) === false
                    for k in 1:n
                        @test cstatus(u, k) === false
                    end

                    fill_vstatus!(u, true)
                    @test all_vstatus(u) === true
                    for k in 1:n
                        @test vstatus(u, k) === true
                    end
                    vstatus!(u, i, false)
                    @test all_vstatus(u) === false
                    fill_vstatus!(u, false)
                    @test all_vstatus(u) === false
                    for k in 1:n
                        @test vstatus(u, k) === false
                    end

                    fill_ustatus!(u, true)
                    @test all_ustatus(u) === true
                    for k in 1:n
                        @test ustatus(u, k) === true
                    end
                    ustatus!(u, i, false)
                    @test all_ustatus(u) === false
                    fill_ustatus!(u, false)
                    @test all_ustatus(u) === false
                    for k in 1:n
                        @test ustatus(u, k) === false
                    end

                end
            end
        end

    end
    
end

end

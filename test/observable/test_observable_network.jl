module RocketNetworkObservableTest

using Test
using Rocket
using Sockets

include("../test_helpers.jl")

# Poll `cond` until it holds or the timeout elapses; returns the final value of `cond()`.
function wait_until(cond; timeout = 5.0, dt = 0.01)
    t0 = time()
    while !cond() && (time() - t0) < timeout
        sleep(dt)
    end
    return cond()
end

@testset "NetworkObservable" begin

    println("Testing: network")

    @testset "Issue #72: emitted arrays are independent copies of the receive buffer" begin
        port, srv = Sockets.listenany(Sockets.localhost, 15000)
        received = Vector{Vector{Float64}}()

        subscription = subscribe!(
            network(Vector{Float64}, Int(port), 16),
            lambda(on_next = v -> push!(received, v)),
        )

        client = accept(srv)
        write(client, 2)
        write(client, [1.0, 2.0])
        write(client, 3)
        write(client, [3.0, 4.0, 5.0])
        flush(client)

        @test wait_until(() -> length(received) >= 2)
        @test received[1] == [1.0, 2.0]
        @test received[2] == [3.0, 4.0, 5.0]
        # the two emissions must not alias the same reused buffer
        @test received[1] !== received[2]

        unsubscribe!(subscription)
        close(client)
        close(srv)
    end

    @testset "Issue #73: an out-of-range length prefix is rejected via error!" begin
        port, srv = Sockets.listenany(Sockets.localhost, 16000)
        errored = Ref{Any}(nothing)

        subscription = subscribe!(
            network(Vector{Float64}, Int(port), 4),
            lambda(on_next = _ -> nothing, on_error = e -> (errored[] = e)),
        )

        client = accept(srv)
        write(client, 999)   # far larger than the buffer size (4)
        flush(client)

        @test wait_until(() -> errored[] !== nothing)
        @test errored[] isa Exception

        unsubscribe!(subscription)
        close(client)
        close(srv)
    end

    @testset "Issue #75: server broadcasts to a network client (lock-guarded paths)" begin
        port, probe = Sockets.listenany(Sockets.localhost, 17000)
        close(probe)   # free the port for the ServerActor's own listen()

        server_actor = server(Vector{Float64}, Int(port))
        received = Vector{Vector{Float64}}()

        subscription = subscribe!(
            network(Vector{Float64}, Int(port), 16),
            lambda(on_next = v -> push!(received, v)),
        )

        # give the server accept task time to register the client socket
        sleep(0.3)

        next!(server_actor, [1.0, 2.0])
        next!(server_actor, [3.0, 4.0])

        @test wait_until(() -> length(received) >= 2)
        @test received[1] == [1.0, 2.0]
        @test received[2] == [3.0, 4.0]

        unsubscribe!(subscription)
        complete!(server_actor)
    end

end

end

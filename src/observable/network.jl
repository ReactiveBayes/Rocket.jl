export network

using Sockets

import Base: ==
import Base: show

# TODO: Untested and undocumented

"""
    LocalNetworkObservable{D, Address, Port, S}()

LocalNetworkObservable listens for the messages of type `D` from remote server with specified `Address` and `Port` parameters.

# See also: [`network`](@ref), [`Subscribable`](@ref)
"""
struct LocalNetworkObservable{D, A, P, S} <: Subscribable{D} end

function on_subscribe!(observable::LocalNetworkObservable{D, Address, Port, S}, actor) where { D, Address, Port, S }
    clientside = Sockets.connect(Address, Port)
    @async begin
        try
            while isopen(clientside)
                count = read(clientside, Int)
                if count === 0
                    complete!(actor)
                    return nothing
                elseif count === -1
                    error!(actor, ErrorException("LocalNetworkObservableError"))
                    return nothing
                else
                    next!(actor, read(clientside, D))
                end
            end
        catch err
            if !(err isa EOFError)
                error!(actor, err)
            end
        end
    end
    return LocalNetworkObservableSubscritpion(clientside)
end

function on_subscribe!(observable::LocalNetworkObservable{Vector{D}, Address, Port, S}, actor) where { D, Address, Port, S }
    clientside = Sockets.connect(Address, Port)
    @async begin
        try
            buffer = Vector{D}(undef, S)
            while isopen(clientside)
                count = read(clientside, Int)
                if count === 0
                    complete!(actor)
                    return nothing
                elseif count === -1
                    error!(actor, ErrorException("LocalNetworkObservableError"))
                    return nothing
                else
                    unsafe_read(clientside, pointer(buffer), count * sizeof(D))
                    next!(actor, unsafe_wrap(Vector{D}, pointer(buffer), count))
                end
            end
        catch err
            if !(err isa EOFError)
                error!(actor, err)
            end
        end
    end
    return LocalNetworkObservableSubscritpion(clientside)
end

struct LocalNetworkObservableSubscritpion <: Teardown
    clientside :: TCPSocket
end

as_teardown(::Type{<:LocalNetworkObservableSubscritpion}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::LocalNetworkObservableSubscritpion)
    close(subscription.clientside)
end

"""
    network(::Type{D}, port::Int)             where D
    network(::Type{D}, address::A, port::Int) where { D, A <: IPAddr }

    network(::Type{Vector{D}}, port::Int, buffer_size::Int)             where D
    network(::Type{Vector{D}}, address::A, port::Int, buffer_size::Int) where { D, A <: IPAddr }

Creation operator for the `LocalNetworkObservable` that emits messages from the server with specified `address` and `port` arguments.

See also: [`LocalNetworkObservable`](@ref), [`subscribe!`](@ref)
"""
network(::Type{D}, port::Int)             where D                  = network(D, Sockets.localhost, port)
network(::Type{D}, address::A, port::Int) where { D, A <: IPAddr } = LocalNetworkObservable{D, address, port, 0}()

network(::Type{Vector{D}}, port::Int)             where D                  = error("Specify maximum buffer size for input data")
network(::Type{Vector{D}}, address::A, port::Int) where { D, A <: IPAddr } = error("Specify maximum buffer size for input data")

network(::Type{Vector{D}}, port::Int, buffer_size::Int)             where D                  = network(Vector{D}, Sockets.localhost, port, buffer_size)
network(::Type{Vector{D}}, address::A, port::Int, buffer_size::Int) where { D, A <: IPAddr } = LocalNetworkObservable{Vector{D}, address, port, buffer_size}()

Base.:(==)(::LocalNetworkObservable{D1, A1, P1}, ::LocalNetworkObservable{D2, A2, P2}) where { D1, A1, P1 } where { D2, A2, P2 } = D1 == D2 && A1 == A2 && P1 == P2

Base.show(io::IO, observable::LocalNetworkObservable{D, A, P}) where { D, A, P } = print(io, "LocalNetworkObservable($D, address = $A, port = $P)")

export server, ServerActor

using Sockets

"""
    ServerActor{D, Address, Port}() where D

The `ServerActor` sends all `next!`/`error!`/`complete!` events to the local network listeners
with specified `Address` and `Port` parameters via `TCPSocket`.

See also: [`Actor`](@ref), [`server`](@ref)
"""
struct ServerActor{D, A, P} <: Actor{D}
    server  :: Sockets.TCPServer
    sockets :: Vector{Sockets.TCPSocket}

    ServerActor{D, A, P}() where { D, A, P } = begin
        self = new(listen(A, P), Vector{Sockets.TCPSocket}())

        @async begin
            while true
                listener = accept(self.server)
                push!(self.sockets, listener)
                filter!(socket -> isopen(socket), self.sockets)
            end
        end

        return self
    end
end

is_exhausted(actor::ServerActor) = !isopen(actor.server)

function on_next!(actor::ServerActor, data)
    filter!(socket -> __send_next(socket, data), actor.sockets)
end

function on_error!(actor::ServerActor, err)
    foreach(socket -> __send_error(socket, err), actor.sockets)
    close(actor.server)
end

function on_complete!(actor::ServerActor)
    foreach(socket -> __send_complete(socket), actor.sockets)
    close(actor.server)
end

function __send_next(socket, data::D) where D
    if isopen(socket)
        try
            return write(socket, 1) !== 0 && write(socket, data) !== 0
        catch _
            return false
        end
    end
    return false
end

function __send_next(socket, data::Vector{D}) where D
    if isopen(socket)
        try
            size = length(data)
            return write(socket, size) !== 0 && write(socket, data) !== 0
        catch _
            return false
        end
    end
    return false
end

function __send_error(socket, err)
    if isopen(socket)
        try
            return write(socket, -1) !== 0
        catch _
            return false
        end
    end
    return false
end

function __send_complete(socket)
    if isopen(socket)
        try
            return write(socket, 0) !== 0
        catch _
            return false
        end
    end
    return false
end

struct ServerActorFactory{Address, Port} <: AbstractActorFactory end

create_actor(::Type{L}, factory::ServerActorFactory{Address, Port}) where { L, Address, Port } = server(L, Address, Port)

"""
    server(port::Int)
    server(address::A, port::Int) where { A <: IPAddr }
    server(::Type{D}, port::Int)
    server(::Type{D}, address::A, port::Int) where { A <: IPAddr }

Creation operator for the `ServerActor` actor.

See also: [`AbstractActor`](@ref)
"""
server(port::Int)                                   = server(Sockets.localhost, port)
server(address::A, port::Int) where { A <: IPAddr } = ServerActorFactory{address, port}()

function server(::Type{D}, port::Int) where D
    return server(D, Sockets.localhost, port)
end

function server(::Type{D}, address::A, port::Int) where { D, A <: IPAddr }
    @assert isbits(zero(D)) "Network server actor supports only primitive data types"
    return ServerActor{D, address, port}()
end

function server(::Type{Vector{D}}, address::A, port::Int) where { D, A <: IPAddr }
    @assert isbits(zero(D)) "Network server actor supports only primitive data types"
    return ServerActor{Vector{D}, address, port}()
end

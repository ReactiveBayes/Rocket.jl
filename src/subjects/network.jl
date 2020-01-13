export LocalNetworkSubject, as_subscribable, on_subscribe!
export on_next!, on_error!, on_complete!, is_exhausted
export close

using Sockets

import Base: close

mutable struct LocalNetworkSubject{D} <: Actor{D}
    port      :: Int
    subject   :: Subject{D}
    server    :: Sockets.TCPServer
    remote    :: Vector{TCPSocket}
    is_closed :: Bool

    LocalNetworkSubject{D}(port) where D = begin
        server = listen(port)
        subject = new(port, Subject{D}(), server, Vector{TCPSocket}(), false)

        @async begin
            while true
                subscriber = accept(server)
                push!(subject.remote, subscriber)
            end
        end

        return subject
    end
end

# TODO
is_exhausted(actor::LocalNetworkSubject) = false

function on_next!(subject::LocalNetworkSubject{D}, data::D) where D
    if !subject.is_closed
        next!(subject.subject, data)
        for r in subject.remote
            if isopen(r)
                write(r, data)
            end
        end
    end
end

function on_error!(subject::LocalNetworkSubject, err)
    if !subject.is_closed
        error!(subject.subject, err)
        for r in subject.remote
            if isopen(r)
                # TODO
                close(r)
            end
        end
    end
end

function on_complete!(subject::LocalNetworkSubject)
    if !subject.is_closed
        complete!(subject.subject)
        for r in subject.remote
            if isopen(r)
                # TODO
                close(r)
            end
        end
    end
end

as_subscribable(::Type{<:LocalNetworkSubject{D}}) where D = ValidSubscribable{D}()

function on_subscribe!(subject::LocalNetworkSubject{D}, actor::A) where { A <: AbstractActor{D} } where D
    if subject.is_closed
        complete!(actor)
        return VoidTeardown()
    else
        return subscribe!(subject.subject, actor)
    end
end

function close(subject::LocalNetworkSubject)
    subject.is_closed = true
    close(subject.server)
end

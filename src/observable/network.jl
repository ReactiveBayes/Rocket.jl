export LocalNetworkObservable, on_subscribe!
export LocalNetworkObservableSubscritpion, as_teardown, on_unsubscribe

using Sockets

struct LocalNetworkObservable{D} <: Subscribable{D}
    port :: Int
end

function on_subscribe!(observable::LocalNetworkObservable{D}, actor) where D
    clientside = Sockets.connect(observable.port)
    @async begin
        try
            while isopen(clientside)
                next!(actor, read(clientside, D))
            end
            complete!(actor)
        catch e
            error!(actor, e)
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

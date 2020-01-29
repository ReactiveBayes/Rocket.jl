export ActorProxy, SourceProxy, ActorSourceProxy
export actor_proxy!, source_proxy!
export ProxyObservable, proxy

import Base: show

"""
    ActorProxy

Can be used as a super type for common proxy object. Automatically specifies `ValidActorProxy` trait behavior. Each `ActorProxy` must implement
its own method for `actor_proxy!(proxy, actor)` function which have to return a valid actor object.

See also: [`proxy`](@ref), [`actor_proxy!`](@ref)
"""
abstract type ActorProxy       end

"""
    SourceProxy

Can be used as a super type for common proxy object. Automatically specifies `ValidSourceProxy` trait behavior. Each `SourceProxy` must implement
its own method for `source_proxy!(proxy, source)` function which have to return a valid subscribable object.

See also: [`proxy`](@ref), [`source_proxy!`](@ref)
"""
abstract type SourceProxy      end

"""
    ActorSourceProxy

Can be used as a super type for common proxy object. Automatically specifies `ValidActorSourceProxy` trait behavior. Each `ActorSourceProxy` must implement
its own method for `source_proxy!(proxy, source)` function which have to return a valid subscribable object and also for `actor_proxy!(proxy, actor)` function which have to return a valid actor object..

See also: [`proxy`](@ref), [`actor_proxy!`](@ref), [`source_proxy!`](@ref)
"""
abstract type ActorSourceProxy end

abstract type ProxyTrait end

struct ValidActorProxy        <: ProxyTrait end
struct ValidSourceProxy       <: ProxyTrait end
struct ValidActorSourceProxy  <: ProxyTrait end
struct InvalidProxy           <: ProxyTrait end

as_proxy(::Type)                     = InvalidProxy()
as_proxy(::Type{<:ActorProxy})       = ValidActorProxy()
as_proxy(::Type{<:SourceProxy})      = ValidSourceProxy()
as_proxy(::Type{<:ActorSourceProxy}) = ValidActorSourceProxy()

call_actor_proxy!(proxy::T, actor::A) where T where A = call_actor_proxy!(as_proxy(T), as_actor(A), proxy, actor)

call_actor_proxy!(as_proxy,                ::InvalidActorTrait,   proxy, actor) = error("Type $(typeof(actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}) or implement as_actor(::Type{<:$(typeof(actor))}).")
call_actor_proxy!(::InvalidProxy,          as_actor,              proxy, actor) = error("Type $(typeof(proxy)) is not a valid proxy type. \nConsider extending your type with one of the ActorProxy, SourceProxy or ActorSourceProxy abstract types or implement as_proxy(::Type{<:$(typeof(proxy))}).")
call_actor_proxy!(::ValidActorProxy,       as_actor,              proxy, actor) = actor_proxy!(proxy, actor)
call_actor_proxy!(::ValidSourceProxy,      as_actor,              proxy, actor) = actor
call_actor_proxy!(::ValidActorSourceProxy, as_actor,              proxy, actor) = actor_proxy!(proxy, actor)

call_source_proxy!(proxy::T, source::S) where T where S = call_source_proxy!(as_proxy(T), as_subscribable(S), proxy, source)

call_source_proxy!(as_proxy,                ::InvalidSubscribable, proxy, source) = error("Type $(typeof(source)) is not a valid subscribable type. \nConsider extending your subscribable with Subscribable{T} abstract type or implement as_subscribable(::Type{<:$(typeof(source))}).")
call_source_proxy!(::InvalidProxy,          as_subscribable,       proxy, source) = error("Type $(typeof(proxy)) is not a valid proxy type. \nConsider extending your type with one of the ActorProxy, SourceProxy or ActorSourceProxy abstract types or implement as_proxy(::Type{<:$(typeof(proxy))}).")
call_source_proxy!(::ValidActorProxy,       as_subscribable,       proxy, source) = source
call_source_proxy!(::ValidSourceProxy,      as_subscribable,       proxy, source) = source_proxy!(proxy, source)
call_source_proxy!(::ValidActorSourceProxy, as_subscribable,       proxy, source) = source_proxy!(proxy, source)

"""
    ProxyObservable{D}(proxied_source, proxy)

An interface for proxied Observables.

See also: [`proxy`](@ref)
"""
struct ProxyObservable{D} <: Subscribable{D}
    proxied_source
    proxy
end

function on_subscribe!(observable::ProxyObservable, actor)
    return subscribe!(observable.proxied_source, call_actor_proxy!(observable.proxy, actor))
end

"""
    actor_proxy!(proxy, actor)

This is function is used to wrap an actor with its proxied version given a particular proxy object. Must return another actor.
Each valid `ActorProxy` and `ActorSourceProxy` must implement its own method for `actor_proxy!` function.

See also: [`proxy`](@ref), [`ActorProxy`](@ref), [`ActorSourceProxy`](@ref)
"""
actor_proxy!(proxy, actor)   = error("You probably forgot to implement actor_proxy!(proxy::$(typeof(proxy)), actor::$(typeof(actor)))")

"""
    source_proxy!(proxy, source)

This is function is used to wrap a source with its proxied version given a particular proxy object. Must return another Observable.
Each valid `SourceProxy` and `ActorSourceProxy` must implement its own method for `source_proxy!` function.

See also: [`proxy`](@ref), [`SourceProxy`](@ref), [`ActorSourceProxy`](@ref)
"""
source_proxy!(proxy, source) = error("You probably forgot to implement source_proxy!(proxy::$(typeof(proxy)), source::$(typeof(source)))")

Base.show(io::IO, observable::ProxyObservable{D}) where D = print(io, "ProxyObservable($D, $(observable.proxy))")

# -------------------------------- #
# Helpers                          #
# -------------------------------- #

"""
    proxy(::Type{D}, source, proxy) where D

Creation operator for the `ProxyObservable` with a given source and proxy objects.

# Example

```jldoctest
using Rx

source = from(1:5)

struct MyCustomProxy <: ActorProxy end

struct MyCustomActor{A} <: Actor{Int}
    actor :: A
end

Rx.on_next!(actor::MyCustomActor, data::Int) = next!(actor.actor, data ^ 2)
Rx.on_error!(actor::MyCustomActor, err)      = error!(actor.actor, err)
Rx.on_complete!(actor::MyCustomActor)        = complete!(actor.actor)

Rx.actor_proxy!(proxy::MyCustomProxy, actor::A) where A = MyCustomActor{A}(actor)

proxied = proxy(Int, source, MyCustomProxy())

subscribe!(proxied, logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 4
[LogActor] Data: 9
[LogActor] Data: 16
[LogActor] Data: 25
[LogActor] Completed
```

See also: [`ProxyObservable`](@ref), [`ActorProxy`](@ref), [`SourceProxy`](@ref), [`ActorSourceProxy`](@ref)
"""
proxy(::Type{D}, source, proxy) where D = as_proxy_observable(D, call_source_proxy!(proxy, source), proxy)

as_proxy_observable(::Type{D}, proxied_source::S, proxy) where D where S = as_proxy_observable(D, as_subscribable(S), proxied_source, proxy)

as_proxy_observable(::Type{D}, ::InvalidSubscribable,  proxied_source, proxy) where D = throw(InvalidSubscribableTraitUsageError(proxied_source))
as_proxy_observable(::Type{D}, ::ValidSubscribable,    proxied_source, proxy) where D = ProxyObservable{D}(proxied_source, proxy)

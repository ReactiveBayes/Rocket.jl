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

call_actor_proxy!(::Type{L}, proxy::T,  actor::A)  where { L, T, A } = call_actor_proxy!(L, as_proxy(T), as_actor(A), proxy, actor)
call_source_proxy!(::Type{L}, proxy::T, source::S) where { L, T, S } = call_source_proxy!(L, as_proxy(T), as_subscribable(S), proxy, source)

# Check for invalid actor trait usages
call_actor_proxy!(::Type, ::InvalidProxy,          ::InvalidActorTrait,   proxy, actor) = error("Type $(typeof(proxy)) is not a valid proxy type. \nConsider extending your type with one of the ActorProxy, SourceProxy or ActorSourceProxy abstract types or implement as_proxy(::Type{<:$(typeof(proxy))}).")
call_actor_proxy!(::Type, ::InvalidProxy,          as_actor,              proxy, actor) = error("Type $(typeof(proxy)) is not a valid proxy type. \nConsider extending your type with one of the ActorProxy, SourceProxy or ActorSourceProxy abstract types or implement as_proxy(::Type{<:$(typeof(proxy))}).")
call_actor_proxy!(::Type, ::ValidActorProxy,       ::InvalidActorTrait,   proxy, actor) = error("Type $(typeof(actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}) or implement as_actor(::Type{<:$(typeof(actor))}).")
call_actor_proxy!(::Type, ::ValidSourceProxy,      ::InvalidActorTrait,   proxy, actor) = error("Type $(typeof(actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}) or implement as_actor(::Type{<:$(typeof(actor))}).")
call_actor_proxy!(::Type, ::ValidActorSourceProxy, ::InvalidActorTrait,   proxy, actor) = error("Type $(typeof(actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}) or implement as_actor(::Type{<:$(typeof(actor))}).")

# Invoke valid proxy and actor
call_actor_proxy!(::Type{L}, ::ValidActorProxy,       ::ValidActorTrait{D}, proxy, actor) where { L, D } = actor_proxy!(L, proxy, actor)
call_actor_proxy!(::Type{L}, ::ValidSourceProxy,      ::ValidActorTrait{D}, proxy, actor) where { L, D } = actor
call_actor_proxy!(::Type{L}, ::ValidActorSourceProxy, ::ValidActorTrait{D}, proxy, actor) where { L, D } = actor_proxy!(L, proxy, actor)

# Check for invalid subscribable trait usages
call_source_proxy!(::Type, ::InvalidProxy,          ::InvalidSubscribable, proxy, source) = error("Type $(typeof(proxy)) is not a valid proxy type. \nConsider extending your type with one of the ActorProxy, SourceProxy or ActorSourceProxy abstract types or implement as_proxy(::Type{<:$(typeof(proxy))}).")
call_source_proxy!(::Type, ::InvalidProxy,          as_subscribable,       proxy, source) = error("Type $(typeof(proxy)) is not a valid proxy type. \nConsider extending your type with one of the ActorProxy, SourceProxy or ActorSourceProxy abstract types or implement as_proxy(::Type{<:$(typeof(proxy))}).")
call_source_proxy!(::Type, as_proxy,                ::InvalidSubscribable, proxy, source) = error("Type $(typeof(source)) is not a valid subscribable type. \nConsider extending your subscribable with Subscribable{T} abstract type or implement as_subscribable(::Type{<:$(typeof(source))}).")

# Invoke valid proxy and source
call_source_proxy!(::Type{L}, ::ValidActorProxy,       ::ValidSubscribableTrait{D}, proxy, source) where { L, D } = source
call_source_proxy!(::Type{L}, ::ValidSourceProxy,      ::ValidSubscribableTrait{D}, proxy, source) where { L, D } = source_proxy!(L, proxy, source)
call_source_proxy!(::Type{L}, ::ValidActorSourceProxy, ::ValidSubscribableTrait{D}, proxy, source) where { L, D } = source_proxy!(L, proxy, source)

"""
    ProxyObservable{L, S, P}(proxied_source::S, proxy::P)

An interface for proxied Observables.

See also: [`proxy`](@ref)
"""
struct ProxyObservable{L, S, P} <: Subscribable{L}
    proxied_source :: S
    proxy          :: P
end

function on_subscribe!(observable::ProxyObservable{L}, actor) where L
    return subscribe!(observable.proxied_source, call_actor_proxy!(L, observable.proxy, actor))
end

"""
    actor_proxy!(::Type, proxy, actor)

This is function is used to wrap an actor with its proxied version given a particular proxy object. Must return another actor.
Each valid `ActorProxy` and `ActorSourceProxy` must implement its own method for `actor_proxy!` function.

See also: [`proxy`](@ref), [`ActorProxy`](@ref), [`ActorSourceProxy`](@ref)
"""
actor_proxy!(L, proxy, actor) = error("You probably forgot to implement actor_proxy!(::Type, proxy::$(typeof(proxy)), actor::$(typeof(actor)))")

"""
    source_proxy!(::Type, proxy, source)

This is function is used to wrap a source with its proxied version given a particular proxy object. Must return another Observable.
Each valid `SourceProxy` and `ActorSourceProxy` must implement its own method for `source_proxy!` function.

See also: [`proxy`](@ref), [`SourceProxy`](@ref), [`ActorSourceProxy`](@ref)
"""
source_proxy!(L, proxy, source) = error("You probably forgot to implement source_proxy!(::Type, proxy::$(typeof(proxy)), source::$(typeof(source)))")

Base.show(io::IO, observable::ProxyObservable{L}) where L = print(io, "ProxyObservable($L, $(observable.proxy))")

# -------------------------------- #
# Helpers                          #
# -------------------------------- #

"""
    proxy(::Type{L}, source, proxy) where L

Creation operator for the `ProxyObservable` with a given source and proxy objects.

# Example

```jldoctest
using Rocket

source = from(1:5)

struct MyCustomProxy <: ActorProxy end

struct MyCustomActor{A} <: Actor{Int}
    actor :: A
end

Rocket.on_next!(actor::MyCustomActor, data::Int) = next!(actor.actor, data ^ 2)
Rocket.on_error!(actor::MyCustomActor, err)      = error!(actor.actor, err)
Rocket.on_complete!(actor::MyCustomActor)        = complete!(actor.actor)

Rocket.actor_proxy!(proxy::MyCustomProxy, actor::A) where A = MyCustomActor{A}(actor)

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
proxy(::Type{L}, source, proxy) where L = as_proxy_observable(L, call_source_proxy!(L, proxy, source), proxy)

as_proxy_observable(::Type{L}, proxied_source::S, proxy) where { L, S } = as_proxy_observable(L, as_subscribable(S), proxied_source, proxy)

as_proxy_observable(::Type{L}, ::InvalidSubscribable,    proxied_source,    proxy)    where L           = throw(InvalidSubscribableTraitUsageError(proxied_source))
as_proxy_observable(::Type{L}, ::ValidSubscribableTrait, proxied_source::S, proxy::P) where { L, S, P } = ProxyObservable{L, S, P}(proxied_source, proxy)

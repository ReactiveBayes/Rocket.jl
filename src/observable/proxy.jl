export ActorProxy, SourceProxy, ActorSourceProxy
export ProxyTrait, ValidProxy, InvalidProxy
export as_proxy, call_actor_proxy!, call_source_proxy!
export ProxyObservable, on_subscribe!
export actor_proxy!, source_proxy!
export proxy

import Base: show

"""
"""
abstract type ActorProxy       end

"""
"""
abstract type SourceProxy      end

"""
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
"""
struct ProxyObservable{D} <: Subscribable{D}
    proxied_source
    proxy
end

function on_subscribe!(observable::ProxyObservable, actor)
    return subscribe!(observable.proxied_source, call_actor_proxy!(observable.proxy, actor))
end

actor_proxy!(proxy, actor)   = error("You probably forgot to implement actor_proxy!(proxy::$(typeof(proxy)), actor::$(typeof(actor)))")
source_proxy!(proxy, source) = error("You probably forgot to implement source_proxy!(proxy::$(typeof(proxy)), source::$(typeof(source)))")

# -------------------------------- #
# Helpers                          #
# -------------------------------- #

proxy(::Type{D}, source, proxy) where D = as_proxy_observable(D, call_source_proxy!(proxy, source), proxy)

as_proxy_observable(::Type{D}, proxied_source::S, proxy) where D where S = as_proxy_observable(D, as_subscribable(S), proxied_source, proxy)

as_proxy_observable(::Type{D}, ::InvalidSubscribable,  proxied_source, proxy) where D = throw(InvalidSubscribableTraitUsageError(proxied_source))
as_proxy_observable(::Type{D}, ::ValidSubscribable,    proxied_source, proxy) where D = ProxyObservable{D}(proxied_source, proxy)

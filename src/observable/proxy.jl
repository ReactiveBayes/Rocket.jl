export ActorProxy, SourceProxy, ActorSourceProxy
export ProxyTrait, ValidProxy, InvalidProxy
export as_proxy, call_actor_proxy!, call_source_proxy!
export ProxyObservable, on_subscribe!
export actor_proxy!, source_proxy!

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

call_actor_proxy!(proxy::T, actor) where T = call_actor_proxy!(as_proxy(T), proxy, actor)

call_actor_proxy!(::InvalidProxy,          proxy, actor) = error("Type $(typeof(proxy)) is not a valid proxy type. Consider extending your type with one of the ActorProxy, SourceProxy or ActorSourceProxy abstract types.")
call_actor_proxy!(::ValidActorProxy,       proxy, actor) = actor_proxy!(proxy, actor)
call_actor_proxy!(::ValidSourceProxy,      proxy, actor) = actor
call_actor_proxy!(::ValidActorSourceProxy, proxy, actor) = actor_proxy!(proxy, actor)

call_source_proxy!(proxy::T, source) where T = call_source_proxy!(as_proxy(T), proxy, source)

call_source_proxy!(::InvalidProxy,          proxy, source) = error("Type $(typeof(proxy)) is not a valid proxy type. Consider extending your type with one of the ActorProxy, SourceProxy or ActorSourceProxy abstract types.")
call_source_proxy!(::ValidActorProxy,       proxy, source) = source
call_source_proxy!(::ValidSourceProxy,      proxy, source) = source_proxy!(proxy, source)
call_source_proxy!(::ValidActorSourceProxy, proxy, source) = source_proxy!(proxy, source)

"""
"""
struct ProxyObservable{D} <: Subscribable{D}
    source
    proxy
end

function on_subscribe!(observable::ProxyObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    proxied_source = call_source_proxy!(observable.proxy, observable.source)
    proxied_actor  = call_actor_proxy!(observable.proxy, actor)
    return subscribe!(proxied_source, proxied_actor)
end

actor_proxy!(proxy, actor) = error("You probably forgot to implement actor_proxy!(proxy::$(typeof(proxy)), actor::$(typeof(actor)))")
source_proxy!(proxy, source) = error("You probably forgot to implement source_proxy!(proxy::$(typeof(proxy)), source::$(typeof(source)))")

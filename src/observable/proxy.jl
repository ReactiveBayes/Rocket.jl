export Proxy
export ProxyTrait, ValidProxy, InvalidProxy
export as_proxy, call_proxy!
export ProxyObservable, on_subscribe!

import Base: show

abstract type Proxy end

abstract type ProxyTrait end

struct ValidProxy   <: ProxyTrait end
struct InvalidProxy <: ProxyTrait end

as_proxy(::Type)          = InvalidProxy()
as_proxy(::Type{<:Proxy}) = ValidProxy()

call_proxy!(proxy::T, actor) where T = call_proxy!(as_proxy(T), proxy, actor)

call_proxy!(::InvalidProxy, proxy, actor) = error("Type $(typeof(proxy)) is not a valid proxy type. Consider extending your type with Proxy abstract type.")
call_proxy!(::ValidProxy,   proxy, actor) = proxy!(proxy, actor)

struct ProxyObservable{D} <: Subscribable{D}
    source
    proxy
end

function on_subscribe!(observable::ProxyObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    return subscribe!(observable.source, call_proxy!(observable.proxy, actor))
end

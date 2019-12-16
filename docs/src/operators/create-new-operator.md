# Create a new operator from scratch

It is more complicated, but if you have to write an operator that cannot be made from a combination of existing operators, you can write an operator from scratch:

Each operator (e.g. `MyFancyOperator`) have to either be a subtype of abstract [`Operator{T, R}`](@ref) type or define a
`Rx.as_operator(::Type{<:MyFancyOperator}) = ValidOperator{T, R}()` trait behavior. In addition, operator must implement `Rx.on_call!(operator::MyFancyOperator, source::S) where { S <: Subscribable{T} }` logic which has to return another Observable as a result of applying `MyFancyOperator` to a `source`.

Note that you must:
- either be a subtype of abstract [`Operator{T, R}`](@ref) type or define a `Rx.as_operator(::Type{<:MyFancyOperator})` trait behavior
- implement `Rx.on_call!(operator::MyFancyOperator, source::S) where { S <: Subscribable{T} }` logic which hast to return another Observable

!!! note
    It is not allowed to modify `source` Observable in any way. You have to return a new observable.

## Proxy observable

It might be useful to use [`ProxyObservable`](@ref) as a return result for an `on_call!` function.
ProxyObservable is a special Observable which proxying actors with the source and/or source with actors.

```julia
struct MyFancyOperator{T} <: Operator{T, T}
    from :: T
end

function Rx.on_call!(operator::MyFancyOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, MyFancyOperatorProxy{T}(operator.from))
end

struct MyFancyOperatorProxy{T} <: ActorProxy
    from :: T
end

Rx.actor_proxy!(proxy::MyFancyOperatorProxy{T}, actor::A) where { A <: AbstractActor{T} } where T = MyFancyProxiedActor{T}(proxy.from, actor)

mutable struct MyFancyProxiedActor{T} <: Actor{T}
    current :: T
    actor
end

function Rx.on_next!(actor::MyFancyProxiedActor{T}, data::T) where T
    actor.current = actor.current + data
end

Rx.on_error!(actor::MyFancyProxiedActor{T}, error) where T = error!(actor.actor, error)

function Rx.on_complete!(actor::MyFancyProxiedActor{T}) where T
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end
```

In this example `on_call!(operator::MyFancyOperator, source::S)` returns a `ProxyObservable` which do not modify an initial stream of data, but sending all data to `MyFancyProxiedActor` actor instead, which is a proxy between source and initial actor in `subscribe!(source, actor)` method.

`on_subscribe!` logic for the ProxyObservable defined as:

```julia
function on_subscribe!(observable::ProxyObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    proxied_source = call_source_proxy!(observable.proxy, observable.source)
    proxied_actor  = call_actor_proxy!(observable.proxy, actor)
    return subscribe!(proxied_source, proxied_actor)
end
```

which is basically maps initial source and actor to its proxies. Proxy object itself (`MyFancyOperatorProxy` e.g.) have to define its proxying behavior with a provided abstract types: [`ActorProxy`](@ref), [`SourceProxy`](@ref), [`ActorSourceProxy`](@ref).

[Under development]

export lowercase

import Base: lowercase
import Base: show

"""
    lowercase()

    Creates an lowercase operator, which forces each value to be in lower case

    # Producing

    Stream of type `<: Subscribable{L}` where L referes to type of data of input Observable

    # Examples

    ```jldoctest
    using Rocket

    source = of("Hello, world!")
    subscribe!(source |> lowercase(), logger())
    ;

    # output

    [LogActor] Data: hello, world!
    [LogActor] Completed
    ```

    See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
lowercase() = LowercaseOperator()

struct LowercaseOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{L}, operator::LowercaseOperator, source) where L
    return proxy(L, source, LowercaseProxy{L}())
end

operator_right(::LowercaseOperator, ::Type{L}) where L = L

struct LowercaseProxy{L} <: ActorProxy end

actor_proxy!(proxy::LowercaseProxy{L}, actor::A) where { L, A } = LowercaseActor{L, A}(actor)

struct LowercaseActor{L, A} <: Actor{L}
    actor :: A
end

is_exhausted(actor::LowercaseActor) = is_exhausted(actor.actor)

on_next!(actor::LowercaseActor{L}, data::L) where L = next!(actor.actor, lowercase(data))
on_error!(actor::LowercaseActor, err)       where L = error!(actor.actor, err)
on_complete!(actor::LowercaseActor)         where L = complete!(actor.actor)

Base.show(io::IO, operator::LowercaseOperator)         = print(io, "LowercaseOperator()")
Base.show(io::IO, proxy::LowercaseProxy{L})    where L = print(io, "LowercaseProxy($L)")
Base.show(io::IO, actor::LowercaseActor{L})    where L = print(io, "LowercaseActor($L)")

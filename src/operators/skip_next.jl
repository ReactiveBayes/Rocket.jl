export skip_next

import Base: show

"""
    skip_next()

Creates a `skip_next` operator, which filters out all `next` messages by the source Observable by emitting only
`error` and `complete` messages.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from_iterable([ 1, 2, 3 ])
subscribe!(source |> skip_next(), logger())
;

# output
[LogActor] Completed

```

See also: [`Operator`](@ref), [`skip_error`](@ref), [`skip_complete`](@ref), [`logger`](@ref)
"""
skip_next() = SkipNextOperator()

struct SkipNextOperator <: Operator end

operator_eltype(::SkipNextOperator, ::Type{L}) where L = L

struct SkipNextSubscribable{L, S} <: Subscribable{L}
    source :: S
end

struct SkipNextActor{A}
    actor :: A
end

function on_call!(::Type{L}, ::Type{L}, operator::SkipNextOperator, source::S) where { L, S }
    return SkipNextSubscribable{L, S}(source)
end

function on_subscribe!(source::SkipNextSubscribable, actor::A) where A
    return subscribe!(source.source, SkipNextActor{A}(actor))
end

on_next!(actor::SkipNextActor, data) = begin end
on_error!(actor::SkipNextActor, err) = error!(actor.actor, err)
on_complete!(actor::SkipNextActor)   = complete!(actor.actor)

Base.show(io::IO, ::SkipNextOperator)                = print(io, "SkipNextOperator()")
Base.show(io::IO, ::SkipNextSubscribable{L}) where L = print(io, "SkipNextProxy($L)")
Base.show(io::IO, ::SkipNextActor)                   = print(io, "SkipNextActor()")

export first

import Base: first

"""
    first()

Creates a first operator, which returns an Observable
that emits only the first value emitted by the source Observable.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rx

struct KeepActor{D} <: NextActor{D}
    values::Vector{D}

    KeepActor{D}() where D = new(Vector{D}())
end

Rx.on_next!(actor::KeepActor{D}, data::D) where D = push!(actor.values, data)

@sync begin
    source = from([ i for i in 1:100 ])
    actor  = KeepActor{Int}()
    subscription = subscribe!(source |> first(), actor)
    println(actor.values)
end
;

# output

[1]
```

See also: [`take`](@ref)
"""
first() = take(1)

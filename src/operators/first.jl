export first

import Base: first

"""
    first(::Type{T}) where T

Creates a first operator, which returns an Observable
that emits only the first value emitted by the source Observable.

# Arguments
- `::Type{T}`: the type of data of source

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
    subscription = subscribe!(source |> first(Int), actor)
    println(actor.values)
end
;

# output

Int64[1]
```

See also: [`take`](@ref), [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
first(::Type{T}) where T = take(T, 1)

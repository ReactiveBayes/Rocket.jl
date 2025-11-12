export defer

import Base: show

"""
    defer(::Type{D}, factoryFn::F) where { D, F <: Function }

Creates an Observable that, on subscribe, calls an Observable factory to make an Observable for each new Observer.

# Arguments
- `T`: type of output data source, created by the `factoryFn`
- `factoryFn`: the Observable factory function to invoke for each Observer that subscribes to the output Observable

# Examples

```jldoctest
using Rocket

source = defer(Int, () -> from([ 1, 2, 3 ]))

subscribe!(source, logger())
;

# output
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

See also: [`Subscribable`](@ref), [`subscribe!`](@ref), [`logger`](@ref)
"""
defer(::Type{D}, factoryFn::F) where {D,F<:Function} = DeferObservable{D,F}(factoryFn)

@subscribable struct DeferObservable{D,F} <: Subscribable{D}
    factoryFn::F
end

function on_subscribe!(observable::DeferObservable, actor)
    source = observable.factoryFn()
    return subscribe!(source, actor)
end

Base.show(io::IO, observable::DeferObservable{D}) where {D} =
    print(io, "DeferObservable($D)")

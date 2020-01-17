export NeverObservable, on_subscribe!
export never

import Base: show

"""
    NeverObservable{D}()

An Observable that emits no items to the Observer and never completes.

# Type parameters
- `D`: Type of Observable data

See also: [`Subscribable`](@ref), [`never`](@ref)
"""
struct NeverObservable{D} <: Subscribable{D} end

function on_subscribe!(observable::NeverObservable, actor)
    return VoidTeardown()
end

"""
    never(T = Any)

Creates a simple Observable that emits neither values nor errors nor the completion notification.
It can be used for testing purposes or for composing with other Observables.
Please note that by never emitting a complete notification, this Observable keeps
the subscription from being disposed automatically. Subscriptions need to be manually
disposed.

# Arguments
- `T`: Type of Observable data, optional, `Any` is the default

# Examples

```jldoctest
using Rx

source = never()
subscribe!(source, logger())
;

# output

```

See also: [`NeverObservable`](@ref), [`subscribe!`](@ref), [`logger`](@ref)
"""
never(T = Any) = NeverObservable{T}()

Base.show(io::IO, observable::NeverObservable{D}) where D = print(io, "NeverObservable($D)")

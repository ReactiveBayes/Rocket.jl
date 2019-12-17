export NeverObservable, on_subscribe!, never

"""
    NeverObservable{D} <: Subscribable{D}

An Observable that emits no items to the Observer and never completes.

# Type parameters
- `D`: Type of Observable data

See also: [`Subscribable`](@ref)
"""
struct NeverObservable{D} <: Subscribable{D} end

function on_subscribe!(observable::NeverObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    return VoidTeardown()
end

"""
    never(T)

Creates a simple Observable that emits neither values nor errors nor the completion notification.
It can be used for testing purposes or for composing with other Observables.
Please note that by never emitting a complete notification, this Observable keeps
the subscription from being disposed automatically. Subscriptions need to be manually
disposed.

# Arguments
- `T`: Type of Observable data

See also: [`NeverObservable`](@ref), [`Subscribable`](@ref)
"""
never(T = Any) = NeverObservable{T}()

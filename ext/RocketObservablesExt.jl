module RocketObservablesExt

# Compatibility layer between Rocket.jl and Observables.jl (the reactive primitive used
# throughout the Makie ecosystem). This extension is loaded automatically by Pkg whenever
# both `Rocket` and `Observables` are available (Julia >= 1.9).
#
# Per the package-extension rules, an extension may only add methods to functions that
# already exist (in the parent package or the weak dependency) - it cannot export new names.
# We therefore expose the bridge purely through existing entry points:
#
#   * Rocket source       -> `Observables.Observable(source)` / `Observable(initial, source)`
#   * `Observables.Observable` -> a valid Rocket subscribable usable with `subscribe!` and operators

using Rocket
using Observables

# ---------------------------------------------------------------------------------------- #
# Direction A: a Rocket source -> an `Observables.Observable` (so Makie can consume it).     #
# ---------------------------------------------------------------------------------------- #

# A minimal `next`-only actor that pushes every Rocket emission into the target Observable.
# Writing `observable[] = value` notifies all of the Observable's listeners (e.g. Makie plots).
struct ObservableUpdateActor{O} <: Rocket.NextActor{Any}
    observable::O
end

Rocket.on_next!(actor::ObservableUpdateActor, data) = setindex!(actor.observable, data)

# Any object that Rocket recognises as a subscribable (plain observables and subjects alike).
const RocketSource = Union{Rocket.AbstractSubscribable, Rocket.AbstractSubject}

# Subscribe the bridge actor and tie the subscription's lifetime to the Observable. The actor
# references the Observable and the Rocket source references the actor, so the Observable keeps
# updating for as long as the source is alive. When the Observable (and source) become
# unreachable, the finalizer disposes of the Rocket subscription.
function bridge_rocket_to_observable!(observable, source)
    subscription = subscribe!(source, ObservableUpdateActor(observable))
    finalizer(observable) do _
        unsubscribe!(subscription)
    end
    return observable
end

# Generic entry point: the caller supplies an explicit initial value. Works for any cold
# observable, subject, or operator pipeline.
function Observables.Observable(initial, source::RocketSource)
    T = Rocket.subscribable_extract_type(source)
    observable = Observables.Observable{T}(initial)
    return bridge_rocket_to_observable!(observable, source)
end

# `BehaviorSubject` always carries a current value, so no initial value is required.
function Observables.Observable(source::Rocket.BehaviorSubjectInstance{D}) where {D}
    observable = Observables.Observable{D}(Rocket.getcurrent(source))
    return bridge_rocket_to_observable!(observable, source)
end

# `RecentSubject` carries its most recently emitted value (or `nothing` if it never emitted).
function Observables.Observable(source::Rocket.RecentSubjectInstance{D}) where {D}
    recent = Rocket.getrecent(source)
    recent === nothing && throw(ArgumentError(
        "cannot create an `Observable` from a `RecentSubject` that has not emitted yet; " *
        "use `Observable(initial, source)` to provide an initial value.",
    ))
    observable = Observables.Observable{D}(recent)
    return bridge_rocket_to_observable!(observable, source)
end

# ---------------------------------------------------------------------------------------- #
# Direction B: an `Observables.Observable` -> a Rocket subscribable (so Rocket operators and  #
# `subscribe!` can consume Makie observables).                                               #
# ---------------------------------------------------------------------------------------- #

# Teardown that detaches the listener registered with `Observables.on`.
struct ObservableSubscription{F} <: Rocket.Teardown
    observerfunc::F
end

Rocket.as_teardown(::Type{<:ObservableSubscription}) = Rocket.UnsubscribableTeardownLogic()

function Rocket.on_unsubscribe!(subscription::ObservableSubscription)
    Observables.off(subscription.observerfunc)
    return nothing
end

# Treat every `AbstractObservable{T}` as a simple Rocket subscribable producing values of type `T`.
Rocket.as_subscribable(::Type{<:Observables.AbstractObservable{T}}) where {T} =
    Rocket.SimpleSubscribableTrait{T}()

function Rocket.on_subscribe!(observable::Observables.AbstractObservable, actor)
    # Emit the current value immediately (BehaviorSubject-like semantics) ...
    next!(actor, observable[])
    # ... then forward every subsequent update.
    observerfunc = Observables.on(observable) do value
        next!(actor, value)
    end
    return ObservableSubscription(observerfunc)
end

end

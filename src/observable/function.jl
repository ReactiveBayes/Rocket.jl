export FunctionObservable, make

import Base: show

"""
    FunctionObservable{D}(f::F)

    FunctionObservable wraps a callback `f`, which is called when the Observable is initially subscribed to.
    This function is given an Actor, to which new values can be nexted (with `next!(actor, data)`),
    or an `error!` method can be called to raise an error, or `complete!` can be called to notify of a successful completion.

    # Arguments
    - `f::F`: function to be invoked on subscription

    See also: [`Subscribable`](@ref), [`make`](@ref)
"""
struct FunctionObservable{D, F} <: Subscribable{D}
    f :: F
end

function on_subscribe!(observable::FunctionObservable{D}, actor::A) where { D, A }
    wrapper = FunctionObservableActorWrapper{D, A}(false, actor)
    subscription = FunctionObservableSubscription{D, A}(wrapper)
    observable.f(wrapper)
    return subscription
end

mutable struct FunctionObservableActorWrapper{D, A} <: Actor{D}
    is_unsubscribed :: Bool
    actor           :: A
end

function on_next!(wrapper::FunctionObservableActorWrapper{D}, data::D) where D
    if !wrapper.is_unsubscribed
        next!(wrapper.actor, data)
    end
end

function on_error!(wrapper::FunctionObservableActorWrapper, err)
    if !wrapper.is_unsubscribed
        error!(wrapper.actor, err)
    end
end

function on_complete!(wrapper::FunctionObservableActorWrapper)
    if !wrapper.is_unsubscribed
        complete!(wrapper.actor)
    end
end

struct FunctionObservableSubscription{D, A} <: Teardown
    wrapper :: FunctionObservableActorWrapper{D, A}
end

as_teardown(::Type{<:FunctionObservableSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::FunctionObservableSubscription)
    subscription.wrapper.is_unsubscribed = true
    return nothing
end

"""
    make(f::Function, type::Type{D})

Creation operator for the `FunctionObservable`.

# Arguments
- `f`: function to be invoked on subscription
- `type`: type of data in observable

# Examples
```jldoctest
using Rocket

source = make(Int) do actor
    next!(actor, 0)
    complete!(actor)
end

subscription = subscribe!(source, logger());
unsubscribe!(subscription)
;

# output

[LogActor] Data: 0
[LogActor] Completed

```

```jldoctest
using Rocket

source = make(Int) do actor
    next!(actor, 0)
    setTimeout(100) do
        next!(actor, 1)
        complete!(actor)
    end
end

subscription = subscribe!(source, logger())
unsubscribe!(subscription)
;

# output

[LogActor] Data: 0
```

See also: [`FunctionObservable`](@ref), [`subscribe!`](@ref), [`logger`](@ref)
"""
make(f::F, type::Type{D}) where { D, F } = FunctionObservable{D, F}(f)

Base.show(io::IO, observable::FunctionObservable{D}) where D  = print(io, "FunctionObservable($D)")
Base.show(io::IO, observable::FunctionObservableActorWrapper) = print(io, "FunctionObservableActorWrapper()")
Base.show(io::IO, observable::FunctionObservableSubscription) = print(io, "FunctionObservableSubscription()")

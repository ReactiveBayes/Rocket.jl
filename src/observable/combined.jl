export combineLatest

import Base: show

"""
    combineLatest(sources...)
    combineLatest(sources::Tuple, isbatch::Bool)
    combineLatest(sources::Tuple, isbatch::Bool, transform::F) where { F <: Function }
    combineLatest(sources::Tuple, isbatch::Bool, transform::Tuple{DataType, F}) where { F <: Function }

Combines multiple Observables to create an Observable whose values are calculated from the latest values of each of its input Observables.

# Arguments
- `sources`: input sources
- `isbatch`: optional boolean flag indicating that combination should be batched, which means that combined observable will reset it's state every time it emits and will emit next time again if and only if every single non-completed one of provided sources emits at least one value again.
- `transform`: optional transformation function with `(data::R) -> R` signature or a tuple containing type of the transformation result and transformation function with `(data::R) -> type` signature

# Examples
```jldoctest
using Rocket

latest = combineLatest(of(1), from(2:5))

subscribe!(latest, logger())
;

# output

[LogActor] Data: (1, 2)
[LogActor] Data: (1, 3)
[LogActor] Data: (1, 4)
[LogActor] Data: (1, 5)
[LogActor] Completed
```

```jldoctest
using Rocket

latest = combineLatest((of(1), from(2:5)), false, (Int, (t) -> t[1] + t[2]))

subscribe!(latest, logger())
;

# output

[LogActor] Data: 3
[LogActor] Data: 4
[LogActor] Data: 5
[LogActor] Data: 6
[LogActor] Completed
```

See also: [`Subscribable`](@ref), [`subscribe!`](@ref)
"""
combineLatest() = error("combineLatest requires at least on observable on input")

combineLatest(args...)                         = combineLatest(tuple(args...))
combineLatest(sources::S) where { S <: Tuple } = combineLatest(sources, false)

combineLatest(sources::S, isbatch::Bool) where { S <: Tuple } = combineLatest(sources, isbatch, identity)

function combineLatest(sources::S, isbatch::Bool, transform::F) where { S <: Tuple, F <: Function }
    stype = Tuple{ map(source -> subscribable_extract_type(source), sources)... }
    return CombineLatestObservable{stype, S, F, isbatch, stype}(sources, transform)
end

function combineLatest(sources::S, isbatch::Bool, transform::Tuple{DataType, F}) where { S <: Tuple, F <: Function }
    stype = Tuple{ map(source -> subscribable_extract_type(source), sources)... }
    return CombineLatestObservable{transform[1], S, F, isbatch, stype}(sources, transform[2])
end

struct CombineLatestInnerActor{L, W, I} <: Actor{L}
    wrapper :: W
end

Base.show(io::IO, inner::CombineLatestInnerActor{L, W, I}) where { L, W, I } = print(io, "CombineLatestInnerActor($L, $I)")

on_next!(actor::CombineLatestInnerActor{L, W, I}, data::L) where { L, W, I } = next_received!(actor.wrapper, data, Val{I}())
on_error!(actor::CombineLatestInnerActor, err)                               = error_received!(actor.wrapper, err)
on_complete!(actor::CombineLatestInnerActor{L, W, I})      where { L, W, I } = complete_received!(actor.wrapper, Val{I}())

struct CombineLatestActorWrapper{S, A, F, B}
    storage     :: S
    actor       :: A
    transformFn :: F

    cstatus :: BitArray{1} # Completion status
    vstatus :: BitArray{1} # Values status

    subscriptions :: Vector{Teardown}

    CombineLatestActorWrapper{S, A, F, B}(storage::S, actor::A, transformFn::F) where { S, A, F, B } = begin
        cstatus = falses(length(storage))
        vstatus = falses(length(storage))
        subscriptions = fill!(Vector{Teardown}(undef, length(storage)), voidTeardown)
        return new(storage, actor, transformFn, cstatus, vstatus, subscriptions)
    end
end

isbatch(::CombineLatestActorWrapper{S, A, F, B}) where { S, A, F, B } = B

cstatus(wrapper::CombineLatestActorWrapper, index) = wrapper.cstatus[index]
vstatus(wrapper::CombineLatestActorWrapper, index) = wrapper.vstatus[index]

dispose(wrapper::CombineLatestActorWrapper) = begin fill!(wrapper.cstatus, true); foreach(s -> unsubscribe!(s), wrapper.subscriptions) end

function next_received!(wrapper::CombineLatestActorWrapper, data, index::Val{I}) where I
    setstorage!(wrapper.storage, data, index)
    wrapper.vstatus[I] = true
    if all(wrapper.vstatus) && !all(wrapper.cstatus)
        if isbatch(wrapper)
            copy!(wrapper.vstatus, wrapper.cstatus)
        end
        next!(wrapper.actor, wrapper.transformFn(snapshot(wrapper.storage)))
    end
end

function error_received!(wrapper::CombineLatestActorWrapper, err)
    dispose(wrapper)
    error!(wrapper.actor, err)
end

function complete_received!(wrapper::CombineLatestActorWrapper, ::Val{I}) where I
    if !all(wrapper.cstatus)
        wrapper.cstatus[I] = true
        if all(wrapper.cstatus) || wrapper.vstatus[I] === false
            dispose(wrapper)
            complete!(wrapper.actor)
        end
    end
end

struct CombineLatestObservable{T, S, F, B, ST} <: Subscribable{T}
    sources     :: S
    transformFn :: F
end

function on_subscribe!(observable::CombineLatestObservable{T, S, F, B, ST}, actor::A) where { T, S, F, B, A, ST }
    storage = getmstorage(ST)
    wrapper = CombineLatestActorWrapper{typeof(storage), A, F, B}(storage, actor, observable.transformFn)

    try
        for (index, source) in enumerate(observable.sources)
            wrapper.subscriptions[index] = subscribe!(source, CombineLatestInnerActor{eltype(source), typeof(wrapper), index}(wrapper))
            if cstatus(wrapper, index) === true && vstatus(wrapper, index) === false
                dispose(wrapper)
                break
            end
        end
    catch err
        error_received!(wrapper, err)
    end

    if all(wrapper.cstatus)
        dispose(wrapper)
    end

    return CombineLatestSubscription(wrapper)
end

struct CombineLatestSubscription{W} <: Teardown
    wrapper :: W
end

as_teardown(::Type{ <: CombineLatestSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::CombineLatestSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::CombineLatestObservable{D}) where D  = print(io, "CombineLatestObservable($D)")
Base.show(io::IO, ::CombineLatestSubscription)           = print(io, "CombineLatestSubscription()")

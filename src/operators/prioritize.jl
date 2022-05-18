export PriorityHandler, prioritize

import Base: show

"""
    PriorityHandler

`PriorityHandler` accepts a list of priority categories and executes only those actions which priority match the current activated priority setting.
Other actions are stored in a buffer and postponed until their priority setting will be activated. It is possible to execute all postponed actions in the order of the original
priority categories list with the `release!` function. `release!` function does not reset current priority. `PriorityHandler` works in pair with the `prioritize` operator.

See also: [`Rocket.setpriority!`](@ref), [`Rocket.setnextpriority!`](@ref)
"""
mutable struct PriorityHandler{N} 
    priorities :: NTuple{N, Symbol}
    cpriority  :: Symbol
    postponed  :: NTuple{N, Vector{Tuple{Any, Any}}}
end

PriorityHandler(priorities::NTuple{N, Symbol}) where N = PriorityHandler(priorities, first(priorities))

function PriorityHandler(priorities::NTuple{N, Symbol}, cpriority::Symbol) where N
    @assert cpriority ∈ priorities "Unknown priority setting $(cpriority) during creation of `PriorityHandler` with priorities $(priorities)"
    return PriorityHandler(priorities, cpriority, ntuple(i -> Vector{Tuple{Any, Any}}(), N))
end

priorities(handler::PriorityHandler) = handler.priorities

postponed(handler::PriorityHandler)                   = handler.postponed
postponed(handler::PriorityHandler, priority::Symbol) = handler.postponed[ findnext(==(priority), priorities(handler), 1) ]

ispriority(handler::PriorityHandler, priority::Symbol) = handler.cpriority === priority

""" 
    setpriority!(handler::PriorityHandler, priority::Symbol)

Sets current priority for `PriorityHandler` to be equal to `priority` label. Releases all postponed actions for this priority label.

See also: [`PriorityHandler`](@ref), [`Rocket.setnextpriority!`](@ref)
"""
function setpriority!(handler::PriorityHandler, priority::Symbol)
    @assert priority ∈ priorities(handler) "Unknown priority setting $(priority) for handler $(handler)"
    handler.cpriority = priority
    foreach(postponed(handler, priority)) do (actor, data)
        next!(actor, data)
    end
    empty!(postponed(handler, priority))
end

"""
    setnextpriority!(handler::PriorityHandler)

Sets current priority label to be equal to the next priority label after currently activated (in a circular manner).

See also: [`PriorityHandler`](@ref), [`Rocket.setpriority!`](@ref)
"""
function setnextpriority!(handler::PriorityHandler)
    cpindex = findnext(==(handler.cpriority), priorities(handler), 1) # current priority index
    nextindex = cpindex + 1
    if nextindex > length(priorities(handler))
        nextindex = 1
    end
    setpriority!(handler, nextindex)
end

function release!(handler::PriorityHandler)
    cpriority = handler.cpriority
    foreach(priorities(handler)) do priority
        setpriority!(handler, priority)
    end
    handler.cpriority = cpriority
end

function Base.push!(handler::PriorityHandler, label::Symbol, actor, data)
    push!(postponed(handler, label), (actor, data))
end

function Base.deleteat!(handler::PriorityHandler, label::Symbol, release::Bool, actor)
    actions = postponed(handler, label)
    indices = findall(t -> t[1] === actor, actions)
    if release 
        for index in indices
            actor, data = actions[index]
            next!(actor, data)
        end
    end
    deleteat!(actions, indices)
end

function Base.show(io::IO, handler::PriorityHandler) 
    println(io, "PriorityHandler()")
    println(io, "  Priorities:        ", handler.priorities)
    println(io, "  Current priority:  ", handler.cpriority)
    println(io, "  Postponed actions: ", map(length, handler.postponed))
end

##


"""
    prioritize(handler::PriorityHandler, label::Symbol, release_on_complete::Bool = true)

Creates a prioritize operator, which postpones events with priority handler `handler`.

Note: This operator does **not** prioritize `error!` events and these are executed as soon as possible. 
Note: `release_on_complete` flag controls whether priority operator should release postponed events in case of a completion event for some actor.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

See also: [`PriorityHandler`](@ref)
"""
prioritize(handler::PriorityHandler, label::Symbol, release_on_complete::Bool = true) = PrioritizeOperator(handler, label, release_on_complete)

struct PrioritizeOperator <: InferableOperator
    handler             :: PriorityHandler
    label               :: Symbol
    release_on_complete :: Bool
end

function on_call!(::Type{L}, ::Type{L}, operator::PrioritizeOperator, source) where { L }
    return proxy(L, source, PrioritizeProxy(operator.handler, operator.label, operator.release_on_complete))
end

operator_right(::PrioritizeOperator, ::Type{L}) where L = L

struct PrioritizeProxy <: ActorSourceProxy
    handler             :: PriorityHandler
    label               :: Symbol
    release_on_complete :: Bool
end

actor_proxy!(::Type{L}, proxy::PrioritizeProxy, actor::A)   where { L, A } = PrioritizeActor{L, A}(actor, proxy.handler, proxy.label, proxy.release_on_complete)
source_proxy!(::Type{L}, proxy::PrioritizeProxy, source::S) where { L, S } = PrioritizeSource{L, S}(source)

struct PrioritizeSource{L, S} <: Subscribable{L}
    source :: S
end

struct PrioritizeActor{L, A} <: Actor{L}
    actor               :: A
    handler             :: PriorityHandler
    label               :: Symbol
    release_on_complete :: Bool
end


struct PrioritizeSubscription{S, A <: PrioritizeActor} <: Teardown
    subscription :: S
    actor        :: A
end

as_teardown(::Type{ <:PrioritizeSubscription }) = UnsubscribableTeardownLogic()

function on_subscribe!(source::PrioritizeSource, actor::PrioritizeActor)
    return PrioritizeSubscription(subscribe!(source.source, actor), actor)
end

function on_unsubscribe!(subscription::PrioritizeSubscription)
    actor = subscription.actor
    deleteat!(actor.handler, actor.label, false, actor.actor)
    return unsubscribe!(subscription.subscription)
end

function on_next!(actor::PrioritizeActor{L}, data::L) where L
    if ispriority(actor.handler, actor.label)
        next!(actor.actor, data)
    else
        push!(actor.handler, actor.label, actor.actor, data)
    end
end

function on_error!(actor::PrioritizeActor, err) 
    deleteat!(actor.handler, actor.label, false, actor.actor)
    error!(actor.actor, err)
end

function on_complete!(actor::PrioritizeActor) 
    deleteat!(actor.handler, actor.label, actor.release_on_complete, actor.actor)
    complete!(actor.actor)
end

Base.show(io::IO, ::PrioritizeOperator)          = print(io, "PrioritizeOperator()")
Base.show(io::IO, ::PrioritizeProxy)             = print(io, "PrioritizeProxy()")
Base.show(io::IO, ::PrioritizeActor{L}) where L  = print(io, "PrioritizeActor($L)")
Base.show(io::IO, ::PrioritizeSource{L}) where L = print(io, "PrioritizeSource($L)")
Base.show(io::IO, ::PrioritizeSubscription)      = print(io, "PrioritizeSubscription()")
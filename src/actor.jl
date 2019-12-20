export UndefinedActorTrait, BaseActorTrait, NextActorTrait, ErrorActorTrait, CompletionActorTrait, ActorTrait
export AbstractActor, Actor, NextActor, ErrorActor, CompletionActor
export next!, error!, complete!
export on_next!, on_error!, on_complete!
export as_actor

"""
Abstract type for all possible actor traits

See also: [`Actor`](@ref), [`BaseActorTrait`](@ref), [`NextActorTrait`](@ref), [`ErrorActorTrait`](@ref), [`CompletionActorTrait`](@ref), [`UndefinedActorTrait`](@ref)
"""
abstract type ActorTrait{T} end

"""
Base actor trait specifies actor to listen for all `next!`, `error!` and `complete!` events.

See also: [`ActorTrait`](@ref), [`Actor`](@ref)
"""
struct BaseActorTrait{T}       <: ActorTrait{T}       end

"""
Next actor trait specifies actor to listen for `next!` events only.

See also: [`ActorTrait`](@ref), [`NextActor`](@ref)
"""
struct NextActorTrait{T}       <: ActorTrait{T}       end

"""
Error actor trait specifies actor to listen for `error!` events only.

See also: [`ActorTrait`](@ref), [`ErrorActor`](@ref)
"""
struct ErrorActorTrait{T}      <: ActorTrait{T}       end

"""
Completion actor trait specifies actor to listen for `complete!` events only.

See also: [`ActorTrait`](@ref), [`CompletionActor`](@ref)
"""
struct CompletionActorTrait{T} <: ActorTrait{T}       end

"""
Default actor trait behavior for any object. Actor with such a trait specificaion cannot be used as a valid actor in `subscribe!` function.
Doing so will raise an error.
"""
struct UndefinedActorTrait     <: ActorTrait{Nothing} end

"""
Abstract type for any actor object

See also: [`Actor`](@ref), [`NextActor`](@ref), [`ErrorActor`](@ref), [`CompletionActor`](@ref)
"""
abstract type AbstractActor{T} end

"""
Can be used as a super type for common actor. Automatically specifies a `BaseActorTrait` trait behavior.
Each `Actor` must implement its own methods for 'on_next!(actor, data)', 'on_error!(actor, err)' and 'on_complete!(actor)' functions.

See also: [`AbstractActor`](@ref), [`BaseActorTrait`](@ref), [`ActorTrait`](@ref), [`on_next!`](@ref), [`on_error!`](@ref), [`on_complete!`](@ref)
"""
abstract type Actor{T}           <: AbstractActor{T} end

"""
Can be used as a super type for "next-only" actor. Automatically specifies a `NextActorTrait` trait behavior.
Each `NextActor` must implement its own methods for 'on_next!(actor, data)' function only.

See also: [`AbstractActor`](@ref), [`NextActorTrait`](@ref), [`ActorTrait`](@ref), [`on_next!`](@ref)
"""
abstract type NextActor{T}       <: AbstractActor{T} end

"""
Can be used as a super type for "error-only" actor. Automatically specifies a `ErrorActorTrait` trait behavior.
Each `ErrorActor` must implement its own methods for 'on_error!(actor, err)' function only.

See also: [`AbstractActor`](@ref), [`ErrorActorTrait`](@ref), [`ActorTrait`](@ref), [`on_error!`](@ref)
"""
abstract type ErrorActor{T}      <: AbstractActor{T} end

"""
Can be used as a super type for "completion-only" actor. Automatically specifies a `CompletionActorTrait` trait behavior.
Each `CompletionActor` must implement its own methods for 'on_complete!(actor)' function only.

See also: [`AbstractActor`](@ref), [`CompletionActorTrait`](@ref), [`ActorTrait`](@ref), [`on_complete!`](@ref)
"""
abstract type CompletionActor{T} <: AbstractActor{T} end

"""
    as_actor(::Type)

This function checks actor trait behavior specification. May be used explicitly to specify actor trait behavior for any object.

See also: [`ActorTrait`](@ref)
"""
as_actor(::Type)                  = UndefinedActorTrait()
as_actor(::Type{<:AbstractActor}) = UndefinedActorTrait()

as_actor(::Type{<:Actor{T}})           where T = BaseActorTrait{T}()
as_actor(::Type{<:NextActor{T}})       where T = NextActorTrait{T}()
as_actor(::Type{<:ErrorActor{T}})      where T = ErrorActorTrait{T}()
as_actor(::Type{<:CompletionActor{T}}) where T = CompletionActorTrait{T}()

next!(actor)            = error("Missing data argument in next! callback")
error!(actor)           = error("Missing error argument in error! callback")
complete!(actor, extra) = error("Extra argument in complete! callback")

"""
    next!(actor, data)

This function is used to deliver a "next" event to an actor with some `data`

See also: [`AbstractActor`](@ref), [`on_next!`](@ref)
"""
next!(actor::T,  data)  where T = actor_on_next!(as_actor(T), actor, data)

"""
    error!(actor, err)

This function is used to deliver a "error" event to an actor with some `err`

See also: [`AbstractActor`](@ref), [`on_error!`](@ref)
"""
error!(actor::T, err)   where T = actor_on_error!(as_actor(T), actor, err)

"""
    complete!(actor)

This function is used to deliver a "complete" event to an actor

See also: [`AbstractActor`](@ref), [`on_complete!`](@ref)
"""
complete!(actor::T)     where T = actor_on_complete!(as_actor(T), actor)

actor_on_next!(::UndefinedActorTrait,     actor, data)                     = error("Type $(typeof(actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}) or implement as_actor(::Type{<:$(typeof(actor))}).")
actor_on_next!(::BaseActorTrait{T},       actor, data::R) where T where R  = error("Actor of type $(typeof(actor)) expects data to be of type $(T), but $(R) was found.")
actor_on_next!(::NextActorTrait{T},       actor, data::R) where T where R  = error("Actor of type $(typeof(actor)) expects data to be of type $(T), but $(R) was found.")
actor_on_next!(::ErrorActorTrait{T},      actor, data::R) where T where R  = error("Actor of type $(typeof(actor)) expects data to be of type $(T), but $(R) was found.")
actor_on_next!(::CompletionActorTrait{T}, actor, data::R) where T where R  = error("Actor of type $(typeof(actor)) expects data to be of type $(T), but $(R) was found.")
actor_on_next!(::BaseActorTrait{T},       actor, data::T) where T = on_next!(actor, data)
actor_on_next!(::NextActorTrait{T},       actor, data::T) where T = on_next!(actor, data)
actor_on_next!(::ErrorActorTrait{T},      actor, data::T) where T = begin end
actor_on_next!(::CompletionActorTrait{T}, actor, data::T) where T = begin end

actor_on_error!(::UndefinedActorTrait,  actor, err) = error("Type $(typeof(actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}).")
actor_on_error!(::BaseActorTrait,       actor, err) = on_error!(actor, err)
actor_on_error!(::NextActorTrait,       actor, err) = begin end
actor_on_error!(::ErrorActorTrait,      actor, err) = on_error!(actor, err)
actor_on_error!(::CompletionActorTrait, actor, err) = begin end

actor_on_complete!(::UndefinedActorTrait,  actor) = error("Type $(typeof(actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}).")
actor_on_complete!(::BaseActorTrait,       actor) = on_complete!(actor)
actor_on_complete!(::NextActorTrait,       actor) = begin end
actor_on_complete!(::ErrorActorTrait,      actor) = begin end
actor_on_complete!(::CompletionActorTrait, actor) = on_complete!(actor)

"""
    on_next!(actor, data)

Both Actor and NextActor objects must implement its own method for `on_next!` function which will be called on "next" event.

See also: [`Actor`](@ref), [`NextActor`](@ref)
"""
on_next!(actor, data)   = error("You probably forgot to implement on_next!(actor::$(typeof(actor)), data::$(typeof(data))).")

"""
    on_error!(actor, err)

Both Actor and ErrorActor objects must implement its own method for `on_error!` function which will be called on "error" event.

See also: [`Actor`](@ref), [`ErrorActor`](@ref)
"""
on_error!(actor, err)   = error("You probably forgot to implement on_error!(actor::$(typeof(actor)), err).")

"""
    on_complete!(actor)

Both Actor and CompletionActor objects must implement its own method for `on_complete!` function which will be called on "complete" event.

See also: [`Actor`](@ref), [`ErrorActor`](@ref)
"""
on_complete!(actor)     = error("You probably forgot to implement on_complete!(actor::$(typeof(actor))).")

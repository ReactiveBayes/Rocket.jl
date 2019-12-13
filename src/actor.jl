export UndefinedActorTrait, BaseActorTrait, NextActorTrait, ErrorActorTrait, CompletionActorTrait, ActorTrait
export AbstractActor, Actor, NextActor, ErrorActor, CompletionActor
export next!, error!, complete!
export on_next!, on_error!, on_complete!
export as_actor

abstract type ActorTrait{T} end

struct UndefinedActorTrait     <: ActorTrait{Nothing} end
struct BaseActorTrait{T}       <: ActorTrait{T}       end
struct NextActorTrait{T}       <: ActorTrait{T}       end
struct ErrorActorTrait{T}      <: ActorTrait{T}       end
struct CompletionActorTrait{T} <: ActorTrait{T}       end

abstract type AbstractActor{T} end
abstract type Actor{T}           <: AbstractActor{T} end
abstract type NextActor{T}       <: AbstractActor{T} end
abstract type ErrorActor{T}      <: AbstractActor{T} end
abstract type CompletionActor{T} <: AbstractActor{T} end

as_actor(::Type)                  = UndefinedActorTrait()
as_actor(::Type{<:AbstractActor}) = UndefinedActorTrait()

as_actor(::Type{<:Actor{T}})           where T = BaseActorTrait{T}()
as_actor(::Type{<:NextActor{T}})       where T = NextActorTrait{T}()
as_actor(::Type{<:ErrorActor{T}})      where T = ErrorActorTrait{T}()
as_actor(::Type{<:CompletionActor{T}}) where T = CompletionActorTrait{T}()

next!(actor)            = error("Missing data argument in next! callback")
error!(actor)           = error("Missing error argument in error! callback")
complete!(actor, extra) = error("Extra argument in complete! callback")

next!(actor::T,  data)  where T = actor_on_next!(as_actor(T), actor, data)
error!(actor::T, err)   where T = actor_on_error!(as_actor(T), actor, err)
complete!(actor::T)     where T = actor_on_complete!(as_actor(T), actor)

actor_on_next!(::UndefinedActorTrait,     actor, data)                     = error("Type $(typeof(actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}).")
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

on_next!(actor, data)   = error("You probably forgot to implement on_next!(actor::$(typeof(actor)), data::$(typeof(data))).")
on_error!(actor, err)   = error("You probably forgot to implement on_error!(actor::$(typeof(actor)), err).")
on_complete!(actor)     = error("You probably forgot to implement on_complete!(actor::$(typeof(actor))).")

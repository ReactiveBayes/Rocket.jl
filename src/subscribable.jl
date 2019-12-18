export SubscribableTrait, ValidSubscribable, InvalidSubscribable
export Subscribable, as_subscribable
export subscribe!, on_subscribe!

abstract type SubscribableTrait{T} end

struct ValidSubscribable{T} <: SubscribableTrait{T} end
struct InvalidSubscribable  <: SubscribableTrait{Nothing} end

abstract type Subscribable{T} end

as_subscribable(::Type)                            = InvalidSubscribable()
as_subscribable(::Type{<:Subscribable{T}}) where T = ValidSubscribable{T}()

function subscribe!(subscribable::T, actor::S) where T where S
    subscribable_on_subscribe!(as_subscribable(T), as_actor(S), subscribable, actor)
end

# TODO: Add a posibility for actors to be a supertype of source data type, for example
# source <: Subscribable{L}
# actor  <: Actor{Union{L, Nothing}}

subscribable_on_subscribe!(::InvalidSubscribable,   S,                     subscribable, actor)                   = error("Type $(typeof(subscribable)) is not a valid subscribable type. \nConsider extending your subscribable with Subscribable{T} abstract type.")
subscribable_on_subscribe!(::ValidSubscribable,     ::UndefinedActorTrait, subscribable, actor)                   = error("Type $(typeof(actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}).")
subscribable_on_subscribe!(::ValidSubscribable{T1}, ::ActorTrait{T2},      subscribable, actor) where T1 where T2 = error("Actor of type $(typeof(actor)) expects data to be of type $(T2), while subscribable of type $(typeof(subscribable)) produces data of type $(T1).")
subscribable_on_subscribe!(::ValidSubscribable{T},  ::ActorTrait{T},       subscribable, actor) where T           = on_subscribe!(subscribable, actor)

on_subscribe!(subscribable, actor) = error("You probably forgot to implement on_subscribe!(subscribable::$(typeof(subscribable)), actor).")

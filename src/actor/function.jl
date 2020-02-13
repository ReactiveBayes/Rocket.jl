export subscribe!

struct FunctionActor{D} <: NextActor{D}
    on_next :: Function
end

on_next!(actor::FunctionActor{D}, data::D) where D = actor.on_next(data)

struct FunctionActorFactory <: AbstractActorFactory
    on_next :: Function
end

create_actor(::Type{L}, factory::FunctionActorFactory) where L = FunctionActor{L}(factory.on_next)

function subscribe!(source, fn::Function)
    return subscribe!(source, FunctionActorFactory(fn))
end

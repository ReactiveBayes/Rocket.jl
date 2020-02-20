export LoggerActor, logger

"""
    LoggerActor{D}(name::String = "LogActor") where D

    The `LoggerActor` logs all `next!`/`error!`/`complete!` events that are sent from an Observable.

    # Constructor arguments
    - `name`: name of the logger. Optional. Default is `LogActor`.

    # Examples

    ```jldoctest
    using Rocket

    source = from([ 0, 1, 2 ])
    subscribe!(source, LoggerActor{Int}())
    ;

    # output

    [LogActor] Data: 0
    [LogActor] Data: 1
    [LogActor] Data: 2
    [LogActor] Completed

    ```

    ```jldoctest
    using Rocket

    source = from([ 0, 1, 2 ])
    subscribe!(source, LoggerActor{Int}("CustomName"))
    ;

    # output

    [CustomName] Data: 0
    [CustomName] Data: 1
    [CustomName] Data: 2
    [CustomName] Completed

    ```

    See also: [`Actor`](@ref), [`logger`](@ref)
"""
struct LoggerActor{D} <: Actor{D}
    name :: String

    LoggerActor{D}(name::String = "LogActor") where D = new(name)
end

is_exhausted(actor::LoggerActor) = false

on_next!(log::LoggerActor{D}, data::D) where D = println("[$(log.name)] Data: $data")
on_error!(log::LoggerActor, err)               = println("[$(log.name)] Error: $err")
on_complete!(log::LoggerActor)                 = println("[$(log.name)] Completed")

struct LoggerActorFactory <: AbstractActorFactory
    name :: String
end

create_actor(::Type{L}, factory::LoggerActorFactory) where L = LoggerActor{L}(factory.name)

"""
    logger(name = "LogActor")
    logger(::Type{T}, name = "LogActor") where T

    Creation operator for the `LoggerActor` actor.

    # Examples

    ```jldoctest
    using Rocket

    actor = logger(Int)
    actor isa LoggerActor{Int}

    # output
    true
    ```

    See also: [`LoggerActor`](@ref), [`AbstractActor`](@ref)
"""
logger(name = "LogActor")                    = LoggerActorFactory(name)
logger(::Type{T}, name = "LogActor") where T = LoggerActor{T}(name)

export LoggerActor
export on_next!, on_error!, on_complete!, is_exhausted
export LoggerActorFactory, create_actor
export logger

"""
    LoggerActor{D}(name::String = "LogActor") where D

Logger actors logs every data emission or error/complete events into standart output

# Constructor arguments
- `name`: name of the logger, optional

# Examples

```jldoctest
using Rx

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
using Rx

source = from([ 0, 1, 2 ])
subscribe!(source, LoggerActor{Int}("MyName"))
;

# output

[MyName] Data: 0
[MyName] Data: 1
[MyName] Data: 2
[MyName] Completed

```


See also: [`Actor`](@ref)
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
    lambda(name = "LogActor")
    logger(::Type{T}, name = "LogActor") where T

Helper function to create a LoggerActor

See also: [`LoggerActor`](@ref), [`AbstractActor`](@ref)
"""
logger(name = "LogActor")                    = LoggerActorFactory(name)
logger(::Type{T}, name = "LogActor") where T = LoggerActor{T}(name)

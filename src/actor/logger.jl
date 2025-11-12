export LoggerActor, logger

"""
    LoggerActor{D}(name::String = "LogActor", io::O) where { D, O }

The `LoggerActor` logs all `next!`/`error!`/`complete!` events that are sent from an Observable.

# Constructor arguments
- `name`: name of the logger. Optional. Default is `LogActor`.
- `io`: io stream to log in, maybe nothing to write to `stdout`

See also: [`Actor`](@ref), [`logger`](@ref)
"""
struct LoggerActor{D,O} <: Actor{D}
    name::String
    io::O

    LoggerActor{D,O}(name::String, io::O) where {D,O} = new(name, io)
end

# Remark: Here nothing for `io` is a workaround for https://github.com/JuliaDocs/Documenter.jl/issues/1245 where println(actor.io, ...) fails on doctest even if actor.io === stdout

on_next!(actor::LoggerActor{D}, data::D) where {D} =
    println(actor.io !== nothing ? actor.io : stdout, "[$(actor.name)] Data: $data")
on_error!(actor::LoggerActor, err) =
    println(actor.io !== nothing ? actor.io : stdout, "[$(actor.name)] Error: $err")
on_complete!(actor::LoggerActor) =
    println(actor.io !== nothing ? actor.io : stdout, "[$(actor.name)] Completed")

struct LoggerActorFactory{O} <: AbstractActorFactory
    name::String
    io::O
end

create_actor(::Type{L}, factory::LoggerActorFactory{O}) where {L,O} =
    LoggerActor{L,O}(factory.name, factory.io)

"""
    logger([ io::IO ], name::String = "LogActor")
    logger(::Type{T}, [ io::IO ], name::String = "LogActor") where T

Creation operator for the `LoggerActor` actor.

# Examples

```jldoctest
using Rocket

source = from([ 0, 1, 2 ])
subscribe!(source, logger())
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
subscribe!(source, logger("CustomName"))
;

# output

[CustomName] Data: 0
[CustomName] Data: 1
[CustomName] Data: 2
[CustomName] Completed
```

```jldoctest
using Rocket

buffer = IOBuffer()

source = from([ 0, 1, 2 ])
subscribe!(source, logger(buffer, "CustomBuffer"))
;

print(String(take!(buffer)))
# output

[CustomBuffer] Data: 0
[CustomBuffer] Data: 1
[CustomBuffer] Data: 2
[CustomBuffer] Completed
```

See also: [`LoggerActor`](@ref), [`AbstractActor`](@ref)
"""
logger(name::String = "LogActor") = LoggerActorFactory(name, nothing)
logger(io::O, name::String = "LogActor") where {O<:IO} = LoggerActorFactory(name, io)

logger(::Type{T}, name::String = "LogActor") where {T} =
    LoggerActor{T,Nothing}(name, nothing)
logger(::Type{T}, io::O, name::String = "LogActor") where {T,O<:IO} =
    LoggerActor{T,O}(name, io)

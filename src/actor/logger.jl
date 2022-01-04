export LoggerActor, logger

import Base: show

"""
    LoggerActor(name::String = "LogActor", io::O) where { O }

The `LoggerActor` logs all `next!`/`error!`/`complete!` events that are sent from an Observable.

# Constructor arguments
- `name`: name of the logger. Optional. Default is `LogActor`.
- `io`: io stream to log in, maybe nothing to write to `stdout`

See also: [`Actor`](@ref), [`logger`](@ref)
"""
struct LoggerActor{O}
    name :: String
    io   :: O

    LoggerActor{O}(name::String, io::O) where O = new(name, io)
end

Base.show(io::IO, actor::LoggerActor) = print(io, "LoggerActor(\"$(actor.name)\", $(actor.io))")

# Remark: Here nothing for `io` is a workaround for https://github.com/JuliaDocs/Documenter.jl/issues/1245 where println(actor.io, ...) fails on doctest even if actor.io === stdout

on_next!(actor::LoggerActor, data) = on_next!(actor.io, actor, data)
on_error!(actor::LoggerActor, err) = on_error!(actor.io, actor, err)
on_complete!(actor::LoggerActor)   = on_complete!(actor.io, actor)

on_next!(::Nothing, actor::LoggerActor, data) = on_next!(stdout, actor, data)
on_error!(::Nothing, actor::LoggerActor, err) = on_error!(stdout, actor, err)
on_complete!(::Nothing, actor::LoggerActor)   = on_complete!(stdout, actor)

on_next!(io::IO, actor::LoggerActor, data) = println(io, "[$(actor.name)] Data: $data")
on_error!(io::IO, actor::LoggerActor, err) = println(io, "[$(actor.name)] Error: $err")
on_complete!(io::IO, actor::LoggerActor)   = println(io, "[$(actor.name)] Completed")

"""
    logger([ io::IO ], name::String = "LogActor")

Creation operator for the `LoggerActor` actor.

# Examples

```jldoctest
using Rocket

source = from_iterable([ 0, 1, 2 ])
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

source = from_iterable([ 0, 1, 2 ])
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

source = from_iterable([ 0, 1, 2 ])
subscribe!(source, logger(buffer, "CustomBuffer"))
;

print(String(take!(buffer)))
# output

[CustomBuffer] Data: 0
[CustomBuffer] Data: 1
[CustomBuffer] Data: 2
[CustomBuffer] Completed
```

See also: [`LoggerActor`](@ref), [`Actor`](@ref)
"""
logger(name::String = "LogActor")                          = LoggerActor{Nothing}(name, nothing)
logger(io::O, name::String = "LogActor") where { O <: IO } = LoggerActor{O}(name, io)

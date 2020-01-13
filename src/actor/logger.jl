export LoggerActor, on_next!, on_error!, on_complete!

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
    name::String

    LoggerActor{D}(name::String = "LogActor") where D = new(name)
end

on_next!(log::LoggerActor{D}, data::D) where D = println("[$(log.name)] Data: $data")
on_error!(log::LoggerActor, err)               = println("[$(log.name)] Error: $err")
on_complete!(log::LoggerActor)                 = println("[$(log.name)] Completed")

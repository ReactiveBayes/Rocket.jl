export start_with

"""
    start_with(object::O) where O

Creates a `start_with` operator, which forces an observable to emit given `object` as a first value.

# Producing

Stream of type `<: Subscribable{Union{L, O}}` where `L` refers to type of source stream `<: Subscribable{L}`

# Examples
```jldoctest
using Rocket

source = from(1:3) |> start_with(0)
subscribe!(source, logger())
;

# output

[LogActor] Data: 0
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
start_with(object) = StartWithOperator(object)

struct StartWithOperator{V} <: InferableOperator
    value :: V
end

function on_call!(::Type{L}, ::Type{R}, operator::StartWithOperator{V}, source) where { L, V, R }
    return proxy(R, source, StartWithProxy{V}(operator.value))
end

operator_right(::StartWithOperator{V}, ::Type{L}) where { V, L } = Union{L, V}

struct StartWithProxy{V} <: SourceProxy
    value :: V
end

source_proxy!(::Type{L}, proxy::StartWithProxy{V}, source::S) where { L, V, S } = StartWithSource{L, V, S}(proxy.value, source)

@subscribable struct StartWithSource{L, V, S} <: Subscribable{L}
    value  :: V
    source :: S
end

function on_subscribe!(source::StartWithSource, actor)
    next!(actor, source.value)
    return subscribe!(source.source, actor)
end

Base.show(io::IO, ::StartWithOperator)              = print(io, "StartWithOperator()")
Base.show(io::IO, ::StartWithProxy)                 = print(io, "StartWithProxy()")
Base.show(io::IO, ::StartWithSource{L}) where { L } = print(io, "StartWithSource($L)")
export start_with

start_with(value) = StartWithOperator(value)

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

struct StartWithSource{L, V, S} <: Subscribable{L}
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
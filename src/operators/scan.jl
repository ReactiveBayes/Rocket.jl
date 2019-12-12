export scan
export ScanOperator, on_call!
export ScanProxy, actor_proxy!
export ScanActor, on_next!, on_error!, on_complete!
export @CreateScanOperator

scan(::Type{T}, ::Type{R}, scanFn::Function, initial::R = zero(R)) where T where R = ScanOperator{T, R}(scanFn, initial)

struct ScanOperator{T, R} <: Operator{T, R}
    scanFn  :: Function
    initial :: R
end

function on_call!(operator::ScanOperator{T, R}, source::S) where { S <: Subscribable{T} } where T where R
    return ProxyObservable{R}(source, ScanProxy{T, R}(operator.scanFn, operator.initial))
end

struct ScanProxy{T, R} <: ActorProxy
    scanFn  :: Function
    initial :: R
end

actor_proxy!(proxy::ScanProxy{T, R}, actor::A) where { A <: AbstractActor{R} } where T where R = ScanActor{T, R}(proxy.scanFn, copy(proxy.initial), actor)

mutable struct ScanActor{T, R} <: Actor{T}
    scanFn  :: Function
    current :: R
    actor
end

function on_next!(r::ScanActor{T, R}, data::T) where T where R
    r.current = Base.invokelatest(r.scanFn, data, r.current)
    next!(r.actor, r.current)
end

on_error!(r::ScanActor{T, R}, error) where T where R = error!(r.actor, error)
on_complete!(r::ScanActor{T, R})     where T where R = complete!(r.actor)

macro CreateScanOperator(name, scanFn)
    operatorName   = Symbol(name, "ScanOperator")
    proxyName      = Symbol(name, "ScanProxy")
    actorName      = Symbol(name, "ScanActor")

    operatorDefinition = quote
        struct $operatorName{T, R} <: Operator{T, R}
            initial :: R

            $(operatorName){T, R}(initial = zero(R)) where T where R = new(initial)
        end

        function Rx.on_call!(operator::($operatorName){T, R}, source::S) where { S <: Subscribable{T} } where T where R
            return ProxyObservable{R}(source, ($proxyName){T, R}(operator.initial))
        end
    end

    proxyDefinition = quote
        struct $proxyName{T, R} <: ActorProxy
            initial :: R
        end

        Rx.actor_proxy!(proxy::($proxyName){T, R}, actor::A) where { A <: Rx.AbstractActor{R} } where T where R = ($actorName){T, R}(copy(proxy.initial), actor)
    end

    actorDefinition = quote
        mutable struct $actorName{T, R} <: Rx.Actor{T}
            current :: R
            actor
        end

        Rx.on_next!(actor::($actorName){T, R}, data::T) where T where R = begin
            __inlined_lambda = $scanFn
            actor.current = __inlined_lambda(data, actor.current)
            next!(actor.actor, actor.current)
        end

        Rx.on_error!(actor::($actorName){T, R}, error) where T where R = error!(actor.actor, error)
        Rx.on_complete!(actor::($actorName){T, R})     where T where R = complete!(actor.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end

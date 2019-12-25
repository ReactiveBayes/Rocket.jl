export combineLatest

struct CombineSingleLeftMapOperator{L, R} <: TypedOperator{R, Tuple{L, R}}
    left::L
end

function on_call!(::Type{R}, ::Type{Tuple{L, R}}, operator::CombineSingleLeftMapOperator{L, R}, source) where L where R
    return ProxyObservable{Tuple{L, R}}(source, CombineSingleLeftMapOperatorProxy{L, R}(operator.left))
end

struct CombineSingleLeftMapOperatorProxy{L, R} <: ActorProxy
    left::L
end

actor_proxy!(proxy::CombineSingleLeftMapOperatorProxy{L, R}, actor::A) where { A <: AbstractActor{Tuple{L, R}} } where L where R = CombineSingleLeftMapOperatorActor{L, R, A}(proxy.left, actor)

struct CombineSingleLeftMapOperatorActor{L, R, A <: AbstractActor{Tuple{L, R}} } <: Actor{R}
    left  :: L
    actor :: A
end

on_next!(m::CombineSingleLeftMapOperatorActor{L, R, A},  data::R) where { A <: AbstractActor{Tuple{L, R}} } where L where R = next!(m.actor, (m.left, data))
on_error!(m::CombineSingleLeftMapOperatorActor{L, R, A}, err)     where { A <: AbstractActor{Tuple{L, R}} } where L where R = error!(m.actor, err)
on_complete!(m::CombineSingleLeftMapOperatorActor{L, R, A})       where { A <: AbstractActor{Tuple{L, R}} } where L where R = complete!(m.actor)

combineLatest(source1::SingleObservable{D1}, source2::S2) where D1 where S2 = combineLatest(source1, as_subscribable(S2), source2)

function combineLatest(source1::SingleObservable{D1}, ::ValidSubscribable{D2}, source2) where D1 where D2
    return source2 |> CombineSingleLeftMapOperator{D1, D2}(source1.value)
end

function combineLatest(source1::SingleObservable{D1}, ::InvalidSubscribable, source2) where D1
    throw(InvalidSubscribableTraitUsageError(source2))
end

struct CombineSingleRightMapOperator{L, R} <: TypedOperator{L, Tuple{L, R}}
    right::R
end

function on_call!(::Type{L}, ::Type{Tuple{L, R}}, operator::CombineSingleRightMapOperator{L, R}, source) where L where R
    return ProxyObservable{Tuple{L, R}}(source, CombineSingleRightMapOperatorProxy{L, R}(operator.right))
end

struct CombineSingleRightMapOperatorProxy{L, R} <: ActorProxy
    right::R
end

actor_proxy!(proxy::CombineSingleRightMapOperatorProxy{L, R}, actor::A) where { A <: AbstractActor{Tuple{L, R}} } where L where R = CombineSingleRightMapOperatorActor{L, R, A}(proxy.right, actor)

struct CombineSingleRightMapOperatorActor{L, R, A <: AbstractActor{Tuple{L, R}} } <: Actor{L}
    right :: R
    actor :: A
end

on_next!(m::CombineSingleRightMapOperatorActor{L, R, A},  data::L) where { A <: AbstractActor{Tuple{L, R}} } where L where R = next!(m.actor, (data, m.right))
on_error!(m::CombineSingleRightMapOperatorActor{L, R, A}, err)     where { A <: AbstractActor{Tuple{L, R}} } where L where R = error!(m.actor, err)
on_complete!(m::CombineSingleRightMapOperatorActor{L, R, A})       where { A <: AbstractActor{Tuple{L, R}} } where L where R = complete!(m.actor)

combineLatest(source1::S1, source2::SingleObservable{D2}) where D2 where S1 = combineLatest(as_subscribable(S1), source1, source2)

function combineLatest(::ValidSubscribable{D1}, source1, source2::SingleObservable{D2}) where D1 where D2
    return source1 |> CombineSingleRightMapOperator{D1, D2}(source2.value)
end

function combineLatest(::InvalidSubscribable, source1, source2::SingleObservable{D2}) where D2
    throw(InvalidSubscribableTraitUsageError(source1))
end

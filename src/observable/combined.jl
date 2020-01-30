export combineLatest
export LatestCombinedActor1, LatestCombinedActor2, LatestCombinedActor3, LatestCombinedActor4, LatestCombinedActor5
export LatestCombinedActor6, LatestCombinedActor7, LatestCombinedActor8, LatestCombinedActor9, LatestCombinedActor10

import Base: show

#####################################################################################################################
# Combine latest macro
#####################################################################################################################

macro GenerateCombineLatest(N, creation_name, observable_name, wrapper_name, type, batch, mappingFn)
    return esc(quote
        #Rx.@GenerateCombineLatestCreationOperator(N, creation_name, observable_name)
        #Rx.@GenerateCombineLatestObservable(N, observable_name, wrapper_name, type)
        Rx.@GenerateCombineLatestObservableActorWrapper(N, wrapper_name, $batch, $mappingFn)
    end)
end

# @GenerateCombineLatest(2, "combineLatest", "CombineLatestObservable", "CombineLatestObservableActorWrapper", nothing, false, d -> d)

#####################################################################################################################
# Combine latest creation operator macro
#####################################################################################################################

macro GenerateCombineLatestCreationOperator(N, pname, pobservable)
    name       = Symbol(pname)
    observable = Symbol(pobservable)

    inner_combine_latest_name = gensym(name)

    combine_latest_f = Expr(:call, name, map(i -> Expr(:(::), Symbol(:source, i), Symbol(:S, i)), collect(1:N))...)
    combine_latest_f = reduce((current, i) -> Expr(:where, current, Symbol(:S, i)), collect(1:N), init = combine_latest_f)
    combine_latest_b = Expr(:call, Symbol(inner_combine_latest_name, N), map(i -> Expr(:call, :as_subscribable, Symbol(:S, i)), collect(1:N))..., map(i -> Symbol(:source, i), collect(1:N))...)

    combine_latest_nr_f = Expr(:call, Symbol(inner_combine_latest_name, N), map(i -> Expr(:(::), Expr(:curly, :ValidSubscribable, Symbol(:D, i))), collect(1:N))..., map(i -> Symbol(:source, i), collect(1:N))...)
    combine_latest_nr_f = reduce((current, i) -> Expr(:where, current, Symbol(:D, i)), collect(1:N), init = combine_latest_nr_f)
    combine_latest_nr_b = Expr(:call, Expr(:curly, Symbol(observable, N), map(i -> Symbol(:D, i), collect(1:N))...), map(i -> Symbol(:source, i), collect(1:N))...)

    combine_latest_nw_f = Expr(:call, Symbol(inner_combine_latest_name, N), map(i -> Symbol(:as_subscribable, i), collect(1:N))..., map(i -> Symbol(:source, i), collect(1:N))...)
    combine_latest_nw_b = Expr(:call, :error, "Cannot create combineLatest observable with given arguments: ", Expr(:vect, map(i -> Symbol(:source, i), collect(1:N))...))

    combine_latest    = Expr(:function, combine_latest_f, combine_latest_b)
    combine_latest_nr = Expr(:function, combine_latest_nr_f, combine_latest_nr_b)
    combine_latest_nw = Expr(:function, combine_latest_nw_f, combine_latest_nw_b)

    generated = quote
        $combine_latest
        $combine_latest_nr
        $combine_latest_nw
    end

    return esc(generated)
end

#####################################################################################################################
# Combine latest observable subscription
#####################################################################################################################

struct CombineLatestSubscription <: Teardown
    wrapper
end

as_teardown(::Type{<:CombineLatestSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::CombineLatestSubscription)
    __dispose(subscription.wrapper)
    return nothing
end

#####################################################################################################################
# Combine latest observable meta operator
#####################################################################################################################

macro GenerateCombineLatestObservable(N, name, wrapper_name, type)
    name         = Symbol(name, N)
    types        = map(i -> Symbol(:D, i), collect(1:N))
    tupled       = type === :nothing ? Expr(:curly, :Tuple, types...) : type
    subscribable = Expr(:curly, :(Rx.Subscribable), tupled)
    wrapper      = Expr(:curly, Symbol(wrapper_name, N), types..., :A)
    fields       = Expr(:block, map(i -> Symbol(:source, i), collect(1:N))...)
    observable   = Expr(:curly, name, types...)
    structure    = Expr(:struct, false, Expr(:<:, observable, subscribable), fields)

    # on_subscribe! function generation
    on_subscribe_f = Expr(:call, :(Rx.on_subscribe!), Expr(:(::), :observable, observable), Expr(:(::), :actor, :A))
    on_subscribe_f = Expr(:where, on_subscribe_f, :A)
    on_subscribe_f = reduce((current, i) -> Expr(:where, current, Symbol(:D, i)), collect(1:N), init = on_subscribe_f)

    on_subscribe_wrapper = Expr(:(=), :wrapper, Expr(:call, wrapper, map(i -> begin s = Symbol(:source, i); :(observable.$s) end, collect(1:N))..., :actor))
    on_subscribe_b = quote
        $on_subscribe_wrapper
        return Rx.CombineLatestSubscription(wrapper)
    end
    on_subscribe = Expr(:function, on_subscribe_f, on_subscribe_b)

    # Base.show function generation
    show_f = Expr(:call, :(Base.show), Expr(:(::), :io, :IO), Expr(:(::), :observable, observable))
    show_f = reduce((current, i) -> Expr(:where, current, Symbol(:D, i)), collect(1:N), init = show_f)
    show_b = Expr(:call, :(print), :io, string(name), "(Tuple(", collect(Iterators.flatten((map(t -> [ t, "," ], types))))..., "))")
    show   = Expr(:function, show_f, show_b)

    generated = quote
        $structure
        $on_subscribe
        $show
    end

    return esc(generated)
end

#####################################################################################################################
# Combine latest actor meta operator
#####################################################################################################################

macro GenerateLatestCombinedActor(n)
    actor        = Symbol(:LatestCombinedActor, n)
    latest       = Symbol(:latest, n)
    is_completed = Symbol(:is_completed, n)

    esc(quote
        struct ($actor){D, W} <: Actor{D}
            wrapper :: W
        end

        function Rx.on_next!(actor::($actor){D}, data::D) where D
            actor.wrapper.$latest = data
            Rx.__next_check_and_emit(actor.wrapper)
        end

        function Rx.on_error!(actor::($actor), err)
            Rx.__dispose_on_error(actor.wrapper)
            Rx.error!(actor.wrapper.actor, err)
        end

        function Rx.on_complete!(actor::($actor))
            actor.wrapper.complete_status[$n] = true
            if actor.wrapper.$latest === nothing
                actor.wrapper.is_completed = true
            end
            Rx.__check_completed(actor.wrapper)
        end

        Base.show(io::IO, a::($actor){D}) where D = print(io, string($actor), "($D)")
    end)
end

function __check_completed(wrapper)
    if wrapper.is_completed || all(wrapper.complete_status)
        __dispose_on_complete(wrapper)
        complete!(wrapper.actor)
    end
end

__dispose_on_complete(wrapper) = begin wrapper.is_completed = true; __dispose(wrapper) end
__dispose_on_error(wrapper)    = begin wrapper.is_failed    = true; __dispose(wrapper) end

function __dispose(wrapper)
    for subscription in wrapper.subscriptions
        unsubscribe!(subscription)
    end
end

__next_check_and_emit(wrapper) = error("__next_check_and_emit is not implemented for wrapper::$(typeof(wrapper))")

#####################################################################################################################
# Combine latest actor wrapper generation macro
#####################################################################################################################

macro GenerateCombineLatestObservableActorWrapper(N, pname, batched, mappingFn)
    name         = Symbol(pname, N)
    types        = map(i -> Symbol(:D, i), collect(1:N))
    wrapper      = Expr(:curly, name, types..., :A)

    # Structure generation
    actor_field     = Expr(:(::), :actor, :A)
    latest          = map(i -> Expr(:(::), Symbol(:latest, i), Expr(:curly, :Union, Symbol(:D, i), :Nothing)), collect(1:N))
    complete_status = Expr(:(::), :complete_status, Expr(:curly, :BitArray, :1))
    is_completed    = Expr(:(::), :is_completed, :Bool)
    is_failed       = Expr(:(::), :is_failed, :Bool)
    subscriptions   = Expr(:(::), :subscriptions, Expr(:curly, :Vector, :Teardown))

    # Constructor generation
    constructor_f = Expr(:call, Expr(:curly, name, types..., :A), map(i -> Symbol(:source, i), collect(1:N))..., Expr(:(::), :actor, :A))
    constructor_f = reduce((current, i) -> Expr(:where, current, Symbol(:D, i)), collect(1:N), init = constructor_f)
    constructor_f = Expr(:where, constructor_f, :A)

    constructor_b_latest     = Expr(:block, map(i -> begin s = Symbol(:latest, i); Expr(:(=), :(wrapper.$s), :nothing) end, collect(1:N))...)
    constructor_b_actor_init = Expr(:block, map(i -> begin
        actor        = Symbol(:actor, i)
        subscription = Symbol(:subscription, i);
        return quote
            $actor        = $(Expr(:call, Expr(:curly, Symbol(:LatestCombinedActor, i), Symbol(:D, i), Expr(:curly, name, types..., :A)), :wrapper))
            $subscription = $(Expr(:call, :subscribe!, Symbol(:source, i), Symbol(:actor, i)))
            if wrapper.is_failed || wrapper.is_completed
                return wrapper
            end
            push!(wrapper.subscriptions, $subscription)
        end
    end, collect(1:N))...)

    constructor_b = quote
        wrapper = new()

        wrapper.actor           = actor
        wrapper.complete_status = falses($N)
        wrapper.is_completed    = false
        wrapper.is_failed       = false
        wrapper.subscriptions   = Vector{Teardown}()


        $constructor_b_latest
        $constructor_b_actor_init

        return wrapper
    end

    constructor = Expr(:(=), constructor_f, constructor_b)

    fields       = Expr(:block, actor_field, latest..., complete_status, is_completed, is_failed, subscriptions, constructor)
    structure    = Expr(:struct, true, wrapper, fields)

    # __next_check_and_emit! generation
    check = quote
        function Rx.__next_check_and_emit(wrapper::($name))
            if !wrapper.is_completed && !wrapper.is_failed && $(reduce((current, i) -> Expr(:(&&), current, begin l = Symbol(:latest, i); quote wrapper.$l !== nothing end end), collect(2:N), init = begin l = Symbol(:latest, 1); quote wrapper.$l !== nothing end end))
                __inline_lambda = $mappingFn
                next!(wrapper.actor, $(Expr(:call, :__inline_lambda, Expr(:tuple, map(i -> begin l = Symbol(:latest, i); quote wrapper.$l end  end, collect(1:N))...))))
                if $batched
                    $(Expr(:block, map(i -> begin
                        c = Expr(:ref, :(wrapper.complete_status), i)
                        l = Symbol(:latest, i)
                        return quote
                            if !$c
                                wrapper.$l = nothing
                            end
                        end
                    end, collect(1:N))...))
                end
            end
        end
    end

    # Base.show generation
    show_f = Expr(:call, :(Base.show), Expr(:(::), :io, :IO), Expr(:(::), :wrapper, name))
    show_b = Expr(:call, :print, string(name))
    show   = Expr(:function, show_f, show_b)

    generated = quote
        $structure
        $check
        $show
    end

    return esc(generated)
end

#####################################################################################################################
# Precompiled versions
#####################################################################################################################

@GenerateLatestCombinedActor(1)
@GenerateLatestCombinedActor(2)
@GenerateLatestCombinedActor(3)
@GenerateLatestCombinedActor(4)
@GenerateLatestCombinedActor(5)
@GenerateLatestCombinedActor(6)
@GenerateLatestCombinedActor(7)
@GenerateLatestCombinedActor(8)
@GenerateLatestCombinedActor(9)
@GenerateLatestCombinedActor(10)

@GenerateCombineLatestCreationOperator(2, "combineLatest", "CombineLatestObservable")
@GenerateCombineLatestCreationOperator(3, "combineLatest", "CombineLatestObservable")
@GenerateCombineLatestCreationOperator(4, "combineLatest", "CombineLatestObservable")
@GenerateCombineLatestCreationOperator(5, "combineLatest", "CombineLatestObservable")
@GenerateCombineLatestCreationOperator(6, "combineLatest", "CombineLatestObservable")
@GenerateCombineLatestCreationOperator(7, "combineLatest", "CombineLatestObservable")
@GenerateCombineLatestCreationOperator(8, "combineLatest", "CombineLatestObservable")
@GenerateCombineLatestCreationOperator(9, "combineLatest", "CombineLatestObservable")
@GenerateCombineLatestCreationOperator(10, "combineLatest", "CombineLatestObservable")

@GenerateCombineLatestObservable(2, "CombineLatestObservable", "CombineLatestObservableActorWrapper", nothing)
@GenerateCombineLatestObservable(3, "CombineLatestObservable", "CombineLatestObservableActorWrapper", nothing)
@GenerateCombineLatestObservable(4, "CombineLatestObservable", "CombineLatestObservableActorWrapper", nothing)
@GenerateCombineLatestObservable(5, "CombineLatestObservable", "CombineLatestObservableActorWrapper", nothing)
@GenerateCombineLatestObservable(6, "CombineLatestObservable", "CombineLatestObservableActorWrapper", nothing)
@GenerateCombineLatestObservable(7, "CombineLatestObservable", "CombineLatestObservableActorWrapper", nothing)
@GenerateCombineLatestObservable(8, "CombineLatestObservable", "CombineLatestObservableActorWrapper", nothing)
@GenerateCombineLatestObservable(9, "CombineLatestObservable", "CombineLatestObservableActorWrapper", nothing)
@GenerateCombineLatestObservable(10, "CombineLatestObservable", "CombineLatestObservableActorWrapper", nothing)

@GenerateCombineLatestObservableActorWrapper(2, "CombineLatestObservableActorWrapper", false, d -> d)
@GenerateCombineLatestObservableActorWrapper(3, "CombineLatestObservableActorWrapper", false, d -> d)
@GenerateCombineLatestObservableActorWrapper(4, "CombineLatestObservableActorWrapper", false, d -> d)
@GenerateCombineLatestObservableActorWrapper(5, "CombineLatestObservableActorWrapper", false, d -> d)
@GenerateCombineLatestObservableActorWrapper(6, "CombineLatestObservableActorWrapper", false, d -> d)
@GenerateCombineLatestObservableActorWrapper(7, "CombineLatestObservableActorWrapper", false, d -> d)
@GenerateCombineLatestObservableActorWrapper(8, "CombineLatestObservableActorWrapper", false, d -> d)
@GenerateCombineLatestObservableActorWrapper(9, "CombineLatestObservableActorWrapper", false, d -> d)
@GenerateCombineLatestObservableActorWrapper(10, "CombineLatestObservableActorWrapper", false, d -> d)

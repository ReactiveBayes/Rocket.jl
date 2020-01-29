module RxProxyObservableTest

using Test
using Rx

@testset "ProxyObservable" begin

    struct DummyType end

    @testset begin
        @test_throws ErrorException proxy(Int, from(1:5), DummyType)
    end

    struct MyActorProxy{L} <: ActorProxy end

    struct MyActor{L, A} <: Actor{L}
        actor :: A
    end

    Rx.actor_proxy!(proxy::MyActorProxy{L}, actor::A) where L where A = MyActor{L, A}(actor)

    Rx.on_next!(actor::MyActor{L}, data::L) where L = next!(actor.actor, data + 1)
    Rx.on_error!(actor::MyActor, err)               = error!(actor.actor, err)
    Rx.on_complete!(actor::MyActor)                 = complete!(actor.actor)

    @testset begin

        source = proxy(Int, from(1:5), MyActorProxy{Int}())
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 2, 3, 4, 5, 6 ]
    end

    struct MySourceProxy{L} <: SourceProxy end

    struct MySource{L, S} <: Subscribable{L}
        source :: S
    end

    Rx.source_proxy!(proxy::MySourceProxy{L}, source::S) where L where S = MySource{L, S}(source)

    function Rx.on_subscribe!(source::MySource, actor)
        next!(actor, 0)
        return subscribe!(source.source, actor)
    end

    @testset begin
        source = proxy(Int, from(1:5), MySourceProxy{Int}())
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 0, 1, 2, 3, 4, 5 ]
    end

end

end

module RocketProxyObservableTest

using Test
using Rocket

@testset "ProxyObservable" begin

    struct DummyType end

    @testset begin
        @test_throws ErrorException proxy(Int, from(1:5), DummyType())
        @test_throws ErrorException proxy(Int, DummyType(), void(Int))
        @test_throws ErrorException proxy(Int, DummyType(), DummyType())
    end

    struct MyActorProxy{L} <: ActorProxy end

    struct MyActor{L, A} <: Actor{L}
        actor :: A
    end

    Rocket.actor_proxy!(proxy::MyActorProxy{L}, actor::A) where L where A = MyActor{L, A}(actor)

    Rocket.on_next!(actor::MyActor{L}, data::L) where L = next!(actor.actor, data + 1)
    Rocket.on_error!(actor::MyActor, err)               = error!(actor.actor, err)
    Rocket.on_complete!(actor::MyActor)                 = complete!(actor.actor)

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

    Rocket.source_proxy!(proxy::MySourceProxy{L}, source::S) where L where S = MySource{L, S}(source)

    function Rocket.on_subscribe!(source::MySource, actor)
        next!(actor, 0)
        return subscribe!(source.source, actor)
    end

    @testset begin
        source = proxy(Int, from(1:5), MySourceProxy{Int}())
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 0, 1, 2, 3, 4, 5 ]
    end

    struct MyActorSourceProxy{L} <: ActorSourceProxy end

    struct MyActor2{L, A} <: Actor{L}
        actor :: A
    end

    Rocket.actor_proxy!(proxy::MyActorSourceProxy{L}, actor::A) where L where A = MyActor2{L, A}(actor)

    Rocket.on_next!(actor::MyActor2{L}, data::L) where L = next!(actor.actor, data + 2)
    Rocket.on_error!(actor::MyActor2, err)               = error!(actor.actor, err)
    Rocket.on_complete!(actor::MyActor2)                 = complete!(actor.actor)

    struct MySource2{L, S} <: Subscribable{L}
        source :: S
    end

    Rocket.source_proxy!(proxy::MyActorSourceProxy{L}, source::S) where L where S = MySource2{L, S}(source)

    function Rocket.on_subscribe!(source::MySource2, actor)
        next!(actor, 1)
        return subscribe!(source.source, actor)
    end

    @testset begin
        source = proxy(Int, from(1:5), MyActorSourceProxy{Int}())
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 3, 3, 4, 5, 6, 7 ]
    end

    @testset begin
        @test_throws Exception actor_proxy!(DummyType(), DummyType())
        @test_throws Exception source_proxy!(DummyType(), DummyType())

        @test_throws Exception Rocket.call_actor_proxy!(DummyType(), DummyType())
        @test_throws Exception Rocket.call_actor_proxy!(DummyType(), void(Any))
        @test_throws Exception Rocket.call_actor_proxy!(MyActorProxy{Int}(), DummyType())
        @test_throws Exception Rocket.call_actor_proxy!(MySourceProxy{Int}(), DummyType())
        @test_throws Exception Rocket.call_actor_proxy!(MyActorSourceProxy{Int}(), DummyType())

        @test_throws Exception Rocket.call_source_proxy!(DummyType(), DummyType())
        @test_throws Exception Rocket.call_source_proxy!(DummyType(), never())
        @test_throws Exception Rocket.call_source_proxy!(MyActorProxy{Int}(), DummyType())
        @test_throws Exception Rocket.call_source_proxy!(MySourceProxy{Int}(), DummyType())
        @test_throws Exception Rocket.call_source_proxy!(MyActorSourceProxy{Int}(), DummyType())
    end

    @testset begin
        source = proxy(Int, from(1:5), MySourceProxy{Int}())
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("ProxyObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

end

end

module RocketProxyObservableTest

using Test
using Rocket

@testset "ProxyObservable" begin

    println("Testing: proxy")

    struct DummyType end

    @testset begin
        @test_throws ErrorException proxy(Int, from(1:5), DummyType())
        @test_throws ErrorException proxy(Int, DummyType(), void(Int))
        @test_throws ErrorException proxy(Int, DummyType(), DummyType())
    end

    struct MyActorProxy <: ActorProxy end

    struct MyActor{L,A} <: Actor{L}
        actor::A
    end

    Rocket.actor_proxy!(::Type{L}, proxy::MyActorProxy, actor::A) where {L,A} =
        MyActor{L,A}(actor)

    Rocket.on_next!(actor::MyActor{L}, data::L) where {L} = next!(actor.actor, data + 1)
    Rocket.on_error!(actor::MyActor, err) = error!(actor.actor, err)
    Rocket.on_complete!(actor::MyActor) = complete!(actor.actor)

    @testset begin
        source = proxy(Int, from(1:5), MyActorProxy())
        actor = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [2, 3, 4, 5, 6]
    end

    struct MySourceProxy <: SourceProxy end

    struct MySource{L,S} <: Subscribable{L}
        source::S
    end

    Rocket.source_proxy!(::Type{L}, proxy::MySourceProxy, source::S) where {L,S} =
        MySource{L,S}(source)

    function Rocket.on_subscribe!(source::MySource, actor)
        next!(actor, 0)
        return subscribe!(source.source, actor)
    end

    @testset begin
        source = proxy(Int, from(1:5), MySourceProxy())
        actor = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [0, 1, 2, 3, 4, 5]
    end

    struct MyActorSourceProxy <: ActorSourceProxy end

    struct MyActor2{L,A} <: Actor{L}
        actor::A
    end

    Rocket.actor_proxy!(::Type{L}, proxy::MyActorSourceProxy, actor::A) where {L,A} =
        MyActor2{L,A}(actor)

    Rocket.on_next!(actor::MyActor2{L}, data::L) where {L} = next!(actor.actor, data + 2)
    Rocket.on_error!(actor::MyActor2, err) = error!(actor.actor, err)
    Rocket.on_complete!(actor::MyActor2) = complete!(actor.actor)

    struct MySource2{L,S} <: Subscribable{L}
        source::S
    end

    Rocket.source_proxy!(::Type{L}, proxy::MyActorSourceProxy, source::S) where {L,S} =
        MySource2{L,S}(source)

    function Rocket.on_subscribe!(source::MySource2, actor)
        next!(actor, 1)
        return subscribe!(source.source, actor)
    end

    @testset begin
        source = proxy(Int, from(1:5), MyActorSourceProxy())
        actor = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [3, 3, 4, 5, 6, 7]
    end

    @testset begin
        @test_throws Exception actor_proxy!(Any, DummyType(), DummyType())
        @test_throws Exception source_proxy!(Any, DummyType(), DummyType())

        @test_throws Exception Rocket.call_actor_proxy!(Any, DummyType(), DummyType())
        @test_throws Exception Rocket.call_actor_proxy!(Any, DummyType(), void(Any))
        @test_throws Exception Rocket.call_actor_proxy!(Any, MyActorProxy(), DummyType())
        @test_throws Exception Rocket.call_actor_proxy!(Any, MySourceProxy(), DummyType())
        @test_throws Exception Rocket.call_actor_proxy!(
            Any,
            MyActorSourceProxy(),
            DummyType(),
        )

        @test_throws Exception Rocket.call_source_proxy!(Any, DummyType(), DummyType())
        @test_throws Exception Rocket.call_source_proxy!(Any, DummyType(), never())
        @test_throws Exception Rocket.call_source_proxy!(Any, MyActorProxy(), DummyType())
        @test_throws Exception Rocket.call_source_proxy!(Any, MySourceProxy(), DummyType())
        @test_throws Exception Rocket.call_source_proxy!(
            Any,
            MyActorSourceProxy(),
            DummyType(),
        )
    end

    @testset begin
        source = proxy(Int, from(1:5), MySourceProxy())
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("ProxyObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

end

end

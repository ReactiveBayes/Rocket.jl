module RocketObservablesExtTest

using Test, Rocket
using Observables

@testset "Observables.jl compatibility extension" begin

    @testset "extension is loaded" begin
        @test Base.get_extension(Rocket, :RocketObservablesExt) !== nothing
    end

    @testset "Rocket -> Observable: BehaviorSubject" begin
        subject = BehaviorSubject(0)
        observable = Observable(subject)

        @test observable isa Observable{Int}
        @test observable[] == 0

        updates = Int[]
        on(value -> push!(updates, value), observable)

        next!(subject, 42)
        @test observable[] == 42

        next!(subject, 100)
        @test observable[] == 100

        @test updates == [42, 100]
    end

    @testset "Rocket -> Observable: generic source with explicit initial value" begin
        subject = Subject(Int)
        observable = Observable(-1, subject)

        @test observable isa Observable{Int}
        @test observable[] == -1

        next!(subject, 7)
        @test observable[] == 7
    end

    @testset "Rocket -> Observable: RecentSubject" begin
        empty_subject = RecentSubject(Int)
        @test_throws ArgumentError Observable(empty_subject)

        subject = RecentSubject(Int)
        next!(subject, 5)
        observable = Observable(subject)
        @test observable[] == 5

        next!(subject, 9)
        @test observable[] == 9
    end

    @testset "Observable -> Rocket: subscribe! and teardown" begin
        observable = Observable(10)

        collected = keep(Int)
        subscription = subscribe!(observable, collected)

        # current value is emitted immediately on subscription
        @test getvalues(collected) == [10]

        observable[] = 20
        observable[] = 30
        @test getvalues(collected) == [10, 20, 30]

        unsubscribe!(subscription)

        observable[] = 40
        @test getvalues(collected) == [10, 20, 30]
    end

    @testset "Observable -> Rocket: operator pipeline" begin
        observable = Observable(1)

        collected = keep(Int)
        subscription = subscribe!(observable |> map(Int, x -> x * 2) |> filter(x -> x > 2), collected)

        observable[] = 2
        observable[] = 3

        # initial 1 -> 2 is filtered out; 2 -> 4 and 3 -> 6 pass
        @test getvalues(collected) == [4, 6]

        unsubscribe!(subscription)
    end

end

end

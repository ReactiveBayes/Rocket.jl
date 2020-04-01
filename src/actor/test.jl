export test_actor, check_isvalid, check_data_equals, check_error_equals
export isreceived, isfailed, iscompleted

import Base: show
import Base: ~

const HighResolutionTimestamp = UInt
const EmptyTimestamp = HighResolutionTimestamp(0x0)

make_timestamp()::HighResolutionTimestamp  = time_ns()

mutable struct DataTestEvent
    data
    timestamp  :: HighResolutionTimestamp
    is_checked :: Bool

    DataTestEvent(data) = new(data, make_timestamp(), false)
end

mutable struct ErrorTestEvent
    err
    timestamp  :: HighResolutionTimestamp
    is_checked :: Bool

    ErrorTestEvent(err) = new(err, make_timestamp(), false)
end

mutable struct CompleteTestEvent
    timestamp  :: HighResolutionTimestamp
    is_checked :: Bool

    CompleteTestEvent() = new(make_timestamp(), false)
end

const TestActorEvent = Union{DataTestEvent, ErrorTestEvent, CompleteTestEvent}

timestamp(event::TestActorEvent)       = event.timestamp
mark_as_checked(event::TestActorEvent) = event.is_checked = true

struct TestActor <: Actor{Any}
    allowed_type :: Type
    data         :: Vector{TestActorEvent}
    errors       :: Vector{TestActorEvent}
    completes    :: Vector{TestActorEvent}
    created_at   :: HighResolutionTimestamp
    condition    :: Condition

    TestActor(type::Type{L}) where L = begin
        return new(L, Vector{TestActorEvent}(), Vector{TestActorEvent}(), Vector{TestActorEvent}(), make_timestamp(), Condition())
    end
end

is_exhausted(actor::TestActor) = false

on_next!(actor::TestActor,  d) = begin push!(data(actor),      DataTestEvent(d));    notify(actor.condition, false) end
on_error!(actor::TestActor, e) = begin push!(errors(actor),    ErrorTestEvent(e));   yield(); notify(actor.condition, true) end
on_complete!(actor::TestActor) = begin push!(completes(actor), CompleteTestEvent()); yield(); notify(actor.condition, true) end

Base.show(io::IO, actor::TestActor) = print(io, "TestActor()")

# Creation operator

test_actor(::Type{L}) where L = TestActor(L)

# Actor factory

test_actor() = TestActorFactory()

struct TestActorFactory <: AbstractActorFactory end

create_actor(::Type{L}, factory::TestActorFactory) where L = test_actor(L)

# Utility functions
isreceived(actor::TestActor)  = length(data(actor))      !== 0
isfailed(actor::TestActor)    = length(errors(actor))    !== 0
iscompleted(actor::TestActor) = length(completes(actor)) !== 0

created_at(actor::TestActor) = actor.created_at
condition(actor::TestActor)  = actor.condition

data(actor::TestActor)      = actor.data
errors(actor::TestActor)    = actor.errors
completes(actor::TestActor) = actor.completes

data_timestamps(actor::TestActor)     = map(e -> timestamp(e), data(actor))
error_timestamps(actor::TestActor)    = map(e -> timestamp(e), errors(actor))
complete_timestamps(actor::TestActor) = map(e -> timestamp(e), completes(actor))

last_data_timestamp(actor::TestActor)     = begin ts = data_timestamps(actor); lastindex(ts) === 0 ? EmptyTimestamp : ts[end] end
last_error_timestamp(actor::TestActor)    = begin ts = error_timestamps(actor); lastindex(ts) === 0 ? EmptyTimestamp : ts[end] end
last_complete_timestamp(actor::TestActor) = begin ts = complete_timestamps(actor); lastindex(ts) === 0 ? EmptyTimestamp : ts[end] end

# Check for actor validness

check_data_equals(actor::TestActor, candidate)  = map(e -> e.data, data(actor))  == candidate || throw(DataEventsEqualityFailedException())
check_error_equals(actor::TestActor, candidate) = map(e -> e.err, errors(actor)) == [ candidate ] || throw(ErrorEventEqualityFailedException())

function check_isvalid(actor::TestActor)

    # Verifying nothing messed up inner structure of the test actor itself
    # --------------------------------------------------------------------

    # Data events should be of type DataTestEvent
    all(e -> e isa DataTestEvent, data(actor)) || throw(DataEventIncorrectTypeException())

    # Error events should be of type DataErrorEvent
    all(e -> e isa ErrorTestEvent, errors(actor)) || throw(ErrorEventIncorrectTypeException())

    # Complete events should be of type DataCompleteEvent
    all(e -> e isa CompleteTestEvent, completes(actor)) || throw(CompleteEventIncorrectTypeException())

    # --------------------------------------------------------------------

    # Actor cannot receive multiple errors events
    isfailed(actor) && length(errors(actor)) !== 1 && throw(MultipleErrorEventsException())

    # Actor cannot receive multiple complete events
    iscompleted(actor) && length(completes(actor)) !== 1 && throw(MultipleCompleteEventsException())

    # Actor cannot have error and complete events simultaneously
    if isfailed(actor) && iscompleted(actor)
        errorts    = last_error_timestamp(actor)
        completets = last_complete_timestamp(actor)
        errorts > completets ? throw(ErrorAfterCompleteEventException()) : throw(CompleteAfterErrorEventException())
    end

    # Actor cannot have next events after error event
    isfailed(actor) && last_error_timestamp(actor) < last_data_timestamp(actor) && throw(NextAfterErrorEventException())

    # Actor cannot have next events after complete event
    iscompleted(actor) && last_complete_timestamp(actor) < last_data_timestamp(actor) && throw(NextAfterCompleteEventException())

    # Timestamps of all data must be an increasing sequence
    issorted(data(actor), lt = Base.isless, by = e -> timestamp(e)) || throw(DataEventIncorrectTimestampsOrderException())

    # Actor must receive data only with allowed type
    all(e -> e.data isa actor.allowed_type, data(actor)) || throw(UnacceptableNextEventDataTypeException())

    return true
end

struct DataEventIncorrectTypeException            <: Exception end
struct ErrorEventIncorrectTypeException           <: Exception end
struct CompleteEventIncorrectTypeException        <: Exception end
struct DataEventIncorrectTimestampsOrderException <: Exception end
struct MultipleErrorEventsException               <: Exception end
struct MultipleCompleteEventsException            <: Exception end
struct ErrorAfterCompleteEventException           <: Exception end
struct CompleteAfterErrorEventException           <: Exception end
struct NextAfterErrorEventException               <: Exception end
struct NextAfterCompleteEventException            <: Exception end
struct UnacceptableNextEventDataTypeException     <: Exception end
struct DataEventsEqualityFailedException          <: Exception end
struct ErrorEventEqualityFailedException          <: Exception end


# Test stream values helpers

test_on_source(source::S, test; maximum_wait::Float64 = 60000.0) where S = test_on_source(as_subscribable(S), source, test, maximum_wait)

function test_on_source(::InvalidSubscribable, source, test, maximum_wait)
    throw(InvalidSubscribableTraitUsageError(source))
end

function test_on_source(::ValidSubscribable{T}, source, test, maximum_wait) where T
    actor = test_actor(T)

    task = @task begin
        try
            subscribe!(source, actor)
        catch e
            println(e)
        end
    end

    is_completed = false

    wakeup = @task begin
        timedwait(() -> is_completed, maximum_wait; pollint = 1.0)
        if !is_completed
            notify(condition(actor), TestOnSourceTimedOutException(), error = true)
        end
    end

    schedule(task)
    schedule(wakeup)

    current_test = test

    while !wait(condition(actor))
        test_against(actor, current_test)

        current_test = current_test.next

        if current_test === nothing
            break
        end
    end

    yield()

    if current_test !== nothing
        test_against(actor, current_test)
    end

    yield()

    test_against(actor, TestActorLastTest())

    is_completed = true

    return true
end

struct TestActorLastTest end

function test_against(actor::TestActor, test::TestActorLastTest)
    check_isvalid(actor)

    all(e -> e.is_checked, data(actor)) || throw(TestActorStreamUncheckedData())
    all(e -> e.is_checked, errors(actor)) || throw(TestActorStreamUncheckedError())
    all(e -> e.is_checked, completes(actor)) || throw(TestActorStreamUncheckedCompletion())
end

struct TestActorErrorTest
    err
    next  :: Nothing

    TestActorErrorTest(err) = new(err, nothing)
end

function test_against(actor::TestActor, test::TestActorErrorTest)
    check_isvalid(actor)

    if !isfailed(actor)
        throw(TestActorStreamMissingExpectedErrorException(test.err))
    end

    if test.err !== nothing
        actual   = Base.first(errors(actor)).err
        expected = test.err

        if actual != test.err
            throw(TestActorStreamIncorrectExpectedErrorException(actual, expected))
        end
    end

    foreach((e) -> mark_as_checked(e), errors(actor))
    return true
end

struct TestActorCompleteTest
    next :: Nothing

    TestActorCompleteTest() = new(nothing)
end

function test_against(actor::TestActor, test::TestActorCompleteTest)
    check_isvalid(actor)

    if !iscompleted(actor)
        throw(TestActorStreamMissingExpectedCompletionException())
    end

    foreach((e) -> mark_as_checked(e), completes(actor))
    return true
end

struct TestActorStreamValuesTest
    starts_from :: Int
    time_passed :: Int
    expected    :: Vector{Any}
    next        :: Any
end

function test_against(actor::TestActor, test::TestActorStreamValuesTest)
    check_isvalid(actor)

    actual   = map(e -> e.data, data(actor))[ test.starts_from:end ]
    expected = test.expected

    if actual != expected
        throw(TestActorStreamIncorrectStreamValuesException(actual, expected))
    end

    if test.time_passed > 0
        time_expected   = UInt(test.time_passed * NANOSECONDS_IN_MILLISECOND)
        time_first      = timestamp(data(actor)[ test.starts_from ])
        time_to_compare = test.starts_from === 1 ? created_at(actor) : timestamp(data(actor)[ test.starts_from - 1 ])

        if (time_first - time_to_compare) * 1.1 < time_expected
            throw(TestActorStreamIncorrectStreamTimePassedException((time_first - time_to_compare) / NANOSECONDS_IN_MILLISECOND, test.time_passed))
        end
    end

    foreach((e) -> mark_as_checked(e), data(actor)[ test.starts_from:end ])

    return true
end

__add_starts_from(test::Nothing, count::Int) = nothing
__add_starts_from(test::TestActorLastTest, count::Int) = test
__add_starts_from(test::TestActorErrorTest, count::Int) = test
__add_starts_from(test::TestActorCompleteTest, count::Int) = test

function __add_starts_from(test::TestActorStreamValuesTest, count::Int)
    if test === nothing
        return nothing
    else
        return TestActorStreamValuesTest(test.starts_from + count, test.time_passed, test.expected, __add_starts_from(test.next, count))
    end
end

function Base.:~(left::TestActorStreamValuesTest, right::TestActorStreamValuesTest)
    return TestActorStreamValuesTest(left.starts_from, left.time_passed, left.expected, __add_starts_from(right, length(left.expected)))
end

function Base.:~(left::Int, right::TestActorStreamValuesTest)
    return TestActorStreamValuesTest(right.starts_from, left, right.expected, right.next)
end

function Base.:~(left::TestActorStreamValuesTest, right::TestActorErrorTest)
    return TestActorStreamValuesTest(left.starts_from, left.time_passed, left.expected, right)
end

function Base.:~(left::TestActorStreamValuesTest, right::TestActorCompleteTest)
    return TestActorStreamValuesTest(left.starts_from, left.time_passed, left.expected, right)
end

macro ts(expr)

    function lookup_tree(expr::Expr)
        if expr.head === :call && expr.args[1] === :~
            return Expr(:call, :~, lookup_tree(expr.args[2]), lookup_tree(expr.args[3]))
        elseif expr.head === :call && expr.args[1] === :e
            return Expr(:call, :TestActorErrorTest, length(expr.args) === 2 ? expr.args[2] : nothing)
        elseif expr.head === :vect
            return Expr(:call, :TestActorStreamValuesTest, 1, 0, [ expr.args... ], nothing)
        end

        error("Invalid usage of @ts macro")
    end

    function lookup_tree(expr::Int)
        return expr
    end

    function lookup_tree(symbol::Symbol)
        if symbol === :c
            return Expr(:call, :TestActorCompleteTest)
        end

        if symbol === :e
            return Expr(:call, :TestActorErrorTest, nothing)
        end

        error("Invalid usage of @ts macro")
    end

    return lookup_tree(expr)
end

struct TestActorStreamIncorrectStreamValuesException <: Exception
    actual
    expected
end

function Base.show(io::IO, exception::TestActorStreamIncorrectStreamValuesException)
    print(io, "Incorrect values in the stream: expected -> $(exception.expected), actual -> $(exception.actual)")
end

struct TestActorStreamIncorrectStreamTimePassedException <: Exception
    actual
    expected
end

function Base.show(io::IO, exception::TestActorStreamIncorrectStreamTimePassedException)
    print(io, "Incorrect time passed in the stream: expected -> >$(exception.expected)ms, actual -> $(exception.actual)ms")
end

struct TestActorStreamMissingExpectedErrorException <: Exception
    err
end

function Base.show(io::IO, exception::TestActorStreamMissingExpectedErrorException)
    print(io, "Stream did not send an error while expected to fail with: ", exception.err)
end

struct TestActorStreamIncorrectExpectedErrorException <: Exception
    actual
    expected
end

function Base.show(io::IO, exception::TestActorStreamIncorrectExpectedErrorException)
    print(io, "Stream sent an incorrect error: expected -> >$(exception.expected), actual -> $(exception.actual)", exception.err)
end

struct TestActorStreamMissingExpectedCompletionException <: Exception end

function Base.show(io::IO, exception::TestActorStreamMissingExpectedCompletionException)
    print(io, "Stream did not send a complete event while expected to do so")
end

struct TestOnSourceTimedOutException <: Exception end

function Base.show(io::IO, ::TestOnSourceTimedOutException)
    print(io, "TestOnSourceTimedOutException()")
end

struct TestActorStreamUncheckedData <: Exception end

function Base.show(io::IO, ::TestActorStreamUncheckedData)
    print(io, "TestActorStreamUncheckedData()")
end

struct TestActorStreamUncheckedError <: Exception end

function Base.show(io::IO, ::TestActorStreamUncheckedError)
    print(io, "TestActorStreamUncheckedError()")
end

struct TestActorStreamUncheckedCompletion <: Exception end

function Base.show(io::IO, ::TestActorStreamUncheckedCompletion)
    print(io, "TestActorStreamUncheckedCompletion()")
end

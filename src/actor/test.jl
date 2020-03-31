export test_actor, check_isvalid, check_data_equals, check_error_equals
export isreceived, isfailed, iscompleted

import Base: show

const HighResolutionTimestamp = UInt
const EmptyTimestamp = HighResolutionTimestamp(0x0)

make_timestamp()::HighResolutionTimestamp  = time_ns()

struct DataTestEvent
    data
    timestamp :: HighResolutionTimestamp

    DataTestEvent(data) = new(data, make_timestamp())
end

struct ErrorTestEvent
    err
    timestamp :: HighResolutionTimestamp

    ErrorTestEvent(err) = new(err, make_timestamp())
end

struct CompleteTestEvent
    timestamp :: HighResolutionTimestamp

    CompleteTestEvent() = new(make_timestamp())
end

const TestActorEvent = Union{DataTestEvent, ErrorTestEvent, CompleteTestEvent}

timestamp(event::TestActorEvent) = event.timestamp

struct TestActor <: Actor{Any}
    allowed_type :: Type
    data         :: Vector{TestActorEvent}
    errors       :: Vector{TestActorEvent}
    completes    :: Vector{TestActorEvent}
end

is_exhausted(actor::TestActor) = false

on_next!(actor::TestActor,  d) = push!(data(actor),      DataTestEvent(d))
on_error!(actor::TestActor, e) = push!(errors(actor),    ErrorTestEvent(e))
on_complete!(actor::TestActor) = push!(completes(actor), CompleteTestEvent())

Base.show(io::IO, actor::TestActor) = print(io, "TestActor()")

# Creation operator

test_actor(::Type{L}) where L = TestActor(L, Vector{TestActorEvent}(), Vector{TestActorEvent}(), Vector{TestActorEvent}())

# Actor factory

test_actor() = TestActorFactory()

struct TestActorFactory <: AbstractActorFactory end

create_actor(::Type{L}, factory::TestActorFactory) where L = test_actor(L)

# Utility functions
isreceived(actor::TestActor)  = length(data(actor))      !== 0
isfailed(actor::TestActor)    = length(errors(actor))    !== 0
iscompleted(actor::TestActor) = length(completes(actor)) !== 0

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

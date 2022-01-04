# 2.0 transition

- actor traits were removed
  - actor abstract type was removed
  - void actor has been renamed to noop actor
  - void() removed - noop() and noopActor constant instead
  - on_* methods for actors removed
  - most of the errors have been removed
  - less exports
- subscribable traits were removed
  - ArrayObservable and from removed - iterable instead, iterable renamed to from_iterable
  - keyword arguments `scheduler` are now just positional arguments
  - removed errors
  - less exports
- schedulers overhauled
  - AbstractScheduler renamed to Scheduler
- teardown traits were removed
  - teardown has been renamed to `AbstractSubscription`
  - void teardown has been renamed to `NoopSubscription`
  - removed errors
  - less exports
- operators
  - AbstractOperator has been renamed Operator
  - LeftTyped and Typed types are removed
  - new types FixedEltypeOperator and InferredEltypeOperator
  - operator_right renamed to operator_eltype
  - removed errors
  - less exports
  - OpType
  - map
    - OpType
- subject
  - almost everything removed relating to traits/types

TODOs
  - decide on names for
    - filter - type piracy
  - document abstract subject factory
  - revise subscribe! in operators
    - maybe define getscheduler and fallback to on_subscribe!
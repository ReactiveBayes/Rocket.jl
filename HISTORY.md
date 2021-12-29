# 2.0 transition

- actor traits were removed
  - void actor has been renamed to noop actor
  - void() removed - noop() and noopActor constant instead
  - on_* methods for actors removed
- subscribable traits were removed
  - ArrayObservable and from removed - iterable instead, iterable renamed to from_iterable
  - keyword arguments `scheduler` are now just positional arguments
- schedulers overhauled
  - AbstractScheduler renamed to Scheduler
- teardown traits were removed
  - teardown has been renamed to `AbstractSubscription`
  - void teardown has been renamed to `NoopSubscription`
# [Schedulers API](@id schedulers_api)

A scheduler controls how and when an observable delivers its actions: the initial subscription and each `next`, `error`, and `complete` event. The default scheduler for almost all observables is the [`AsapScheduler`](@ref), which runs every action as soon as possible. The [`AsyncScheduler`](@ref) delivers messages asynchronously instead. Both are described on the [Subjects](@ref section_subjects) page.

## Interface

Every scheduler is a subtype of `AbstractScheduler` and implements the following interface.

```@docs
Rocket.AbstractScheduler
Rocket.getscheduler
Rocket.scheduled_subscription!
Rocket.scheduled_next!
Rocket.scheduled_error!
Rocket.scheduled_complete!
Rocket.makeinstance
Rocket.instancetype
```

## Threads scheduler

```@docs
Rocket.ThreadsScheduler
```

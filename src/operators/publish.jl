export publish, publish_behavior, publish_replay, publish_recent

"""
    publish(; scheduler = AsapScheduler())

`publish()` is a shortcut for `multicast(SubjectFactory())`

See also: [`Operator`](@ref), [`multicast`](@ref), [`SubjectFactory`](@ref)
"""
publish(; scheduler = AsapScheduler()) = multicast(SubjectFactory(scheduler))

"""
    publish_behavior(default; scheduler = AsapScheduler())

`publish_behavior(default)` is a shortcut for `multicast(BehaviorSubjectFactory(default))`

See also: [`Operator`](@ref), [`multicast`](@ref), [`BehaviorSubjectFactory`](@ref)
"""
publish_behavior(default; scheduler = AsapScheduler()) = multicast(BehaviorSubjectFactory(default, scheduler = scheduler))

"""
    publish_replay(size::Int; scheduler = AsapScheduler())

`publish_replay(size)` is a shortcut for `multicast(ReplaySubjectFactory(size))`

See also: [`Operator`](@ref), [`multicast`](@ref), [`ReplaySubjectFactory`](@ref)
"""
publish_replay(size::Int; scheduler = AsapScheduler()) = multicast(ReplaySubjectFactory(size, scheduler = scheduler))

"""
    publish_recent(; scheduler = AsapScheduler())

`publish_recent(size)` is a shortcut for `multicast(RecentSubjectFactory())`

See also: [`Operator`](@ref), [`multicast`](@ref), [`RecentSubjectFactory`](@ref)
"""
publish_recent(; scheduler = AsapScheduler()) = multicast(RecentSubjectFactory(scheduler = scheduler))

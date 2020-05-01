export publish
export publish_behavior
export publish_replay

"""
    publish(; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

`publish()` is a shortcut for `multicast(SubjectFactory())`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`SubjectFactory`](@ref)
"""
publish(; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler } = multicast(SubjectFactory(scheduler))

"""
    publish_behavior(default; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

`publish_behavior(default)` is a shortcut for `multicast(BehaviorSubjectFactory(default))`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`BehaviorSubjectFactory`](@ref)
"""
publish_behavior(default; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler } = multicast(BehaviorSubjectFactory(default, scheduler = scheduler))

"""
    publish_replay(size::Int; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

`publish_replay(size)` is a shortcut for `multicast(ReplaySubjectFactory(size))`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`ReplaySubjectFactory`](@ref)
"""
publish_replay(size::Int; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler } = multicast(ReplaySubjectFactory(size, scheduler = scheduler))

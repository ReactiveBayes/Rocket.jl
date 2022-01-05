export share, share_replay, share_recent

"""
    share(; scheduler = AsapScheduler())

`share()` is a shortcut for `publish() + ref_count()`

See also: [`Operator`](@ref), [`multicast`](@ref), [`publish`](@ref), [`ref_count`](@ref)
"""
share(; scheduler = AsapScheduler()) = publish(scheduler = scheduler) + ref_count()

"""
    share_behavior(default; scheduler = AsapScheduler())

`share_behavior(default)` is a shortcut for `publish_behavior(size) + ref_count()`

See also: [`Operator`](@ref), [`multicast`](@ref), [`publish`](@ref), [`publish_behavior`](@ref), [`ref_count`](@ref)
"""
share_behavior(default; scheduler = AsapScheduler()) = publish_behavior(default, scheduler = scheduler) + ref_count()

"""
    share_replay(size::Int; scheduler = AsapScheduler())

`share_replay(size)` is a shortcut for `publish_replay(size) + ref_count()`

See also: [`Operator`](@ref), [`multicast`](@ref), [`publish`](@ref), [`publish_replay`](@ref), [`ref_count`](@ref)
"""
share_replay(size::Int; scheduler = AsapScheduler()) = publish_replay(size, scheduler = scheduler) + ref_count()

"""
    share_recent(; scheduler = AsapScheduler())

`share_recent()` is a shortcut for `publish_recent() + ref_count()`

See also: [`Operator`](@ref), [`multicast`](@ref), [`publish`](@ref), [`publish_recent`](@ref), [`ref_count`](@ref)
"""
share_recent(; scheduler = AsapScheduler()) = publish_recent(scheduler = scheduler) + ref_count()

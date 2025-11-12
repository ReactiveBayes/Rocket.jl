export share
export share_replay
export share_recent

"""
    share(; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

`share()` is a shortcut for `publish() + ref_count()`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`publish`](@ref), [`ref_count`](@ref)
"""
share(; scheduler::H = AsapScheduler()) where {H<:AbstractScheduler} =
    publish(scheduler = scheduler) + ref_count()

"""
    share_replay(size::Int; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

`share_replay(size)` is a shortcut for `publish_replay(size) + ref_count()`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`publish`](@ref), [`publish_replay`](@ref), [`ref_count`](@ref)
"""
share_replay(size::Int; scheduler::H = AsapScheduler()) where {H<:AbstractScheduler} =
    publish_replay(size, scheduler = scheduler) + ref_count()

"""
    share_recent(; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

`share_recent()` is a shortcut for `publish_recent() + ref_count()`

See also: [`AbstractOperator`](@ref), [`multicast`](@ref), [`publish`](@ref), [`publish_recent`](@ref), [`ref_count`](@ref)
"""
share_recent(; scheduler::H = AsapScheduler()) where {H<:AbstractScheduler} =
    publish_recent(scheduler = scheduler) + ref_count()

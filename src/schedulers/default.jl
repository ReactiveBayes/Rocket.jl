struct DefaultScheduler end

function getscheduler(::Type{T}) where T
    return DefaultScheduler()
end

function scheduled_subscription!(::DefaultScheduler, source, actor)
    return on_subscribe!(source, actor)
end

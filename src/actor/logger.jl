export LoggerActor, on_next!, on_error!, on_complete!

struct LoggerActor{D} <: Actor{D}
    name::String

    LoggerActor{D}(name::String = "LogActor") where D = new(name)
end

on_next!(log::LoggerActor{D}, data::D)  where D = println("[$(log.name)] Data: $data")
on_error!(log::LoggerActor{D}, error)   where D = println("[$(log.name)] Error: $error")
on_complete!(log::LoggerActor{D})       where D = println("[$(log.name)] Completed")

export LogActor, on_next!, on_error!, on_complete!

struct LogActor{D} <: Actor{D}
    name::String

    LogActor{D}(name::String = "LogActor") where D = new(name)
end

on_next!(log::LogActor{D}, data::D)  where D = println("[$(log.name)] Data: $data")
on_error!(log::LogActor{D}, error)   where D = println("[$(log.name)] Error: $error")
on_complete!(log::LogActor{D})       where D = println("[$(log.name)] Completed")

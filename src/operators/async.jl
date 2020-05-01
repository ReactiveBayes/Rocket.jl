export async

import Base: close
import Base: show

"""
    async()

Creates an async operator, which sends items from the source Observable asynchronously.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref)
"""
async(size::Int = typemax(Int)) = schedule_on(AsyncScheduler(size))

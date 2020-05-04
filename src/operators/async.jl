export async

import Base: close
import Base: show

"""
    async(size::Int = typemax(Int))

Creates an async operator, which sends items from the source Observable asynchronously.

# Arguments
- `size`: Asynchronous messages buffer size, default is a `typemax(Int)`

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref)
"""
async(size::Int = typemax(Int)) = schedule_on(AsyncScheduler(size))

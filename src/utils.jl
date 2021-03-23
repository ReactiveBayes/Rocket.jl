export MILLISECONDS_IN_SECOND, NANOSECONDS_IN_SECOND, NANOSECONDS_IN_MILLISECOND
export setTimeout

const MILLISECONDS_IN_SECOND     = 1_000.0::Float64
const NANOSECONDS_IN_SECOND      = 1_000_000_000.0::Float64
const NANOSECONDS_IN_MILLISECOND = 1_000_000.0::Float64

"""
    setTimeout(f::Function, timeout::Int)

Creates a `Task` which will asynchornously invoke fucntion `f` after specified `timeout` time in milliseconds.

# Arguments
- `f`::Function, function to be invoked asynchronously
- `timeout`::Int, timeout in milliseconds

# Examples

```
using Rocket
using Dates

println("Before: ", Dates.format(now(), "MM:SS"))
setTimeout(1000) do
    println("Inside: ", Dates.format(now(), "MM:SS"))
end
println("Right after: ", Dates.format(now(), "MM:SS"))
;

# Logs
# Before: 20:59
# Right after: 20:59
# Inside: 21:00
```
"""
function setTimeout(f::Function, timeout::Int)
    @async begin
        sleep(timeout / MILLISECONDS_IN_SECOND)
        f()
    end
end

"""
    combined_type(sources)

Returns a Tuple el-type of observable el-types in `sources` argument in the same order
"""
combined_type(sources) = Tuple{ map(source -> subscribable_extract_type(source), sources)... }

"""
    union_type(sources)

Returns a Union el-type of observable el-types in `sources` argument
"""
union_type(sources) = Union{ map(source -> subscribable_extract_type(source), sources)... }


"""
    similar_typeof(something, ::Type{L})

Returns a result of `typeof(similar(something, L))`. Provides and optimised, allocation-free method for built-in AbstractArray.
"""
similar_typeof(::AbstractArray{T, N}, ::Type{L}) where { T, N, L } = Array{L, N}
similar_typeof(something, ::Type{L})             where { L }       = typeof(similar(something, L))

export MILLISECONDS_IN_SECOND
export setTimeout

const MILLISECONDS_IN_SECOND = 1000.0::Float64

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

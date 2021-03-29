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

__extract_structure_name(expr::Symbol) = expr
__extract_structure_name(expr::Expr)   = expr.args[1]

# There is an annoying bug in Julia multiple dispatch which prevents proper traits recursion optimisation
# Until this bug is fixed we mark all observables and subject structures in Rocket with @subscribable macro to hotfix this bug
# It pre-generates `subscribe!` methods with concrete observable types
# https://github.com/JuliaLang/julia/issues/37045
# This is a monkey-patch and will be removed as soon as the bug itslef is fixed in Julia language
macro subscribable(structure)
    @assert structure.head === :struct "@subscribable macro accepts structure definitions only"
    @assert structure.args[2].head === :(<:) "@subscribable macro accepts structure with Subscribable, ScheduledSubscribable or Subject definitions only"
    
    name = __extract_structure_name(structure.args[2].args[1])

    @assert structure.args[2].args[2].head === :curly
    @assert structure.args[2].args[2].args[1] ∈ (:Subscribable, :ScheduledSubscribable, :AbstractSubject)

    type = structure.args[2].args[2].args[1]

    # generated = if type === :Subscribable || type === :AbstractSubject
    #     map(actor_type -> :(Rocket.subscribe!(observable::$(name){D}, actor::$(actor_type){D}) where D = Rocket.on_subscribe!(observable, actor)), actor_types)
    # elseif type === :ScheduledSubscribable
    #     map(actor_type -> :(Rocket.subscribe!(observable::$(name){D}, actor::$(actor_type){D}) where D = Rocket.scheduled_subscription!(observable, actor, Rocket.makeinstance(D, Rocket.getscheduler(observable)))), actor_types)
    # else
    #     error("Unreacheable in @subscribable macro")
    # end

    structure = quote
        Core.@__doc__ $structure

        @generate_subscribe!($name, $type)
    end

    return esc(structure)
end

macro generate_subscribe!(name::Symbol, type::Symbol)
    actor_types = (
        :(Rocket.Actor),
        :(Rocket.NextActor),
        :(Rocket.ErrorActor),
        :(Rocket.CompletionActor),
        :(Rocket.Subject),
        :(Rocket.BehaviorSubjectInstance),
        :(Rocket.PendingSubjectInstance),
        :(Rocket.RecentSubjectInstance),
        :(Rocket.ReplaySubjectInstance)
    )

    generated = if type === :Subscribable || type === :AbstractSubject
        map(actor_type -> :(Rocket.subscribe!(observable::$(name){D}, actor::$(actor_type){D}) where D = Rocket.on_subscribe!(observable, actor)), actor_types)
    elseif type === :ScheduledSubscribable
        map(actor_type -> :(Rocket.subscribe!(observable::$(name){D}, actor::$(actor_type){D}) where D = Rocket.scheduled_subscription!(observable, actor, Rocket.makeinstance(D, Rocket.getscheduler(observable)))), actor_types)
    else
        error("Unreacheable in @subscribable macro")
    end
    return quote 
        $(generated...)
    end
end
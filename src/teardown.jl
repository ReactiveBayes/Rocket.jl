export TeardownLogic, UnsubscribableTeardownLogic, CallableTeardownLogic, VoidTeardownLogic, UndefinedTeardownLogic
export Teardown, as_teardown
export unsubscribe!, teardown!, on_unsubscribe!

"""
Abstract type for all possible teardown logic traits

See also: [`UnsubscribableTeardownLogic`](@ref), [`CallableTeardownLogic`](@ref), [`VoidTeardownLogic`](@ref), [`UndefinedTeardownLogic`](@ref)
"""
abstract type TeardownLogic end

"""
Unsubscribable teardown logic trait behavior. Unsubscribable teardown object must define its own method
for `on_unsubscribe!()` function which will be invoked when actor decides to 'unsubscribe!' from Observable.

See also: [`TeardownLogic`](@ref)
"""
struct UnsubscribableTeardownLogic <: TeardownLogic end

"""
Callable teardown logic trait behavior. Callable teardown object must be callable (insert meme with a surprised Pikachu here).

See also: [`TeardownLogic`](@ref)
"""
struct CallableTeardownLogic       <: TeardownLogic end

"""
Void teardown logic trait behavior. Void teardown object does nothing in 'unsubscribe!'.

See also: [`TeardownLogic`](@ref)
"""
struct VoidTeardownLogic           <: TeardownLogic end

"""
Default teardown logic trait behavour. Invalid teardwon object cannob be used in `unsubscribe!` function. Doing so will raise an error.

See also: [`TeardownLogic`](@ref)
"""
struct UndefinedTeardownLogic      <: TeardownLogic end

"""
Abstract type for any teardown object

See also: [`TeardownLogic`](@ref)
"""
abstract type Teardown end

"""
    as_teardown(::Type)

This function checks teardown trait behavior specification. Should be used explicitly to specify teardown logic trait behavior for any object.

# Examples

```jldoctest
using Rx

struct MySubscription <: Teardown end

Rx.as_teardown(::Type{<:MySubscription}) = UnsubscribableTeardownLogic()
Rx.on_unsubscribe!(s::MySubscription) = println("Unsubscribed!")

subscription = MySubscription()
unsubscribe!(subscription)
;

# output

Unsubscribed!
```

See also: [`Teardown`](@ref), [`TeardownLogic`](@ref)
"""
as_teardown(::Type)             = UndefinedTeardownLogic()
as_teardown(::Type{<:Function}) = CallableTeardownLogic()

"""
    unsubscribe!(o::T) where T

`unsubscribe!` function is used to cancel Observable execution and to dispose any kind of resources used during an Observable execution.

See also: [`Teardown`](@ref), [`TeardownLogic`](@ref)
"""
unsubscribe!(o::T) where T = teardown!(as_teardown(T), o)

teardown!(::UnsubscribableTeardownLogic, o) = on_unsubscribe!(o)
teardown!(::CallableTeardownLogic, o)       = o()
teardown!(::VoidTeardownLogic, o)           = begin end
teardown!(::UndefinedTeardownLogic, o)      = error("Type $(typeof(o)) has undefined teardown behavior. \nConsider implement as_teardown(::Type{<:$(typeof(o))}).")

"""
    on_unsubscribe!(o)

Each valid teardown object with UnsubscribableTeardownLogic trait behavior must implement its own method
for `on_unsubscribe!()` function which will be invoked when actor decides to 'unsubscribe!' from Observable.

See also: [`Teardown`](@ref), [`TeardownLogic`](@ref), [`UnsubscribableTeardownLogic`](@ref)
"""
on_unsubscribe!(o) = error("You probably forgot to implement on_unsubscribe!(unsubscribable::$(typeof(o))).")

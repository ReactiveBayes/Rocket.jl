export TeardownLogic, UnsubscribableTeardownLogic, CallableTeardownLogic, VoidTeardownLogic, UndefinedTeardownLogic
export Teardown, as_teardown
export unsubscribe!, teardown!, on_unsubscribe!

abstract type TeardownLogic end

struct UnsubscribableTeardownLogic <: TeardownLogic end
struct CallableTeardownLogic       <: TeardownLogic end
struct VoidTeardownLogic           <: TeardownLogic end
struct UndefinedTeardownLogic      <: TeardownLogic end

abstract type Teardown end

as_teardown(::Type)             = UndefinedTeardownLogic()
as_teardown(::Type{<:Function}) = CallableTeardownLogic()

unsubscribe!(o::T) where T = teardown!(as_teardown(T), o)

teardown!(::UnsubscribableTeardownLogic, o) = on_unsubscribe!(o)
teardown!(::CallableTeardownLogic, o)       = o()
teardown!(::VoidTeardownLogic, o)           = begin end
teardown!(::UndefinedTeardownLogic, o)      = error("Type $(typeof(o)) has undefined teardown behavior. \nConsider implement as_teardown(::Type{<:$(typeof(o))}).")

on_unsubscribe!(o) = error("You probably forgot to implement on_unsubscribe!(unsubscribable::$(typeof(o))).")

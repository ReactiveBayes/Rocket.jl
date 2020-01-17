export ChainTeardown, as_teardown, on_unsubscribe!
export chain

"""
    ChainTeardown{T <: Teardown}

ChainTeardown object wraps another teardown and calls its teardown logic on unsubscription.

See also: [`Teardown`](@ref), [`UnsubscribableTeardownLogic`](@ref), [`chain`](@ref)
"""
struct ChainTeardown <: Teardown
    teardown
end

as_teardown(::Type{<:ChainTeardown}) = UnsubscribableTeardownLogic()

on_unsubscribe!(chained::ChainTeardown) = unsubscribe!(chained.teardown)

"""
    chain(t::T) where { T <: Teardown }

Creates a ChainTeardown object with a given teardown `t`

See also: [`Teardown`](@ref), [`ChainTeardown`](@ref)
"""
chain(t::T) where { T <: Teardown } = ChainTeardown(t)

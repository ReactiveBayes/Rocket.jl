export ChainTeardown, as_teardown, on_unsubscribe!
export chain

"""
    ChainTeardown{T <: Teardown}

ChainTeardown object wraps another teardown and calls its teardown logic on unsubscription.
"""
struct ChainTeardown{T <: Teardown} <: Teardown
    teardown::T
end

as_teardown(::Type{<:ChainTeardown}) = UnsubscribableTeardownLogic()

on_unsubscribe!(c::ChainTeardown{T}) where { T <: Teardown } = unsubscribe!(c.teardown)

"""
    chain(t::T) where { T <: Teardown }

Creates ChainTeardown with a given teardown `t`
"""
chain(t::T) where { T <: Teardown } = ChainTeardown{T}(t)

export first

first(::Type{T}) where T = take(T, 1)

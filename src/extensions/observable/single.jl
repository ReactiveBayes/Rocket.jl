export on_call!
export combineLatest

# Speficic method for map operator over SingleObservable
function on_call!(::Type{L}, ::Type{R}, operator::MapOperator{R}, source::SingleObservable{L}) where L where R
    return of(operator.mappingFn(source.value))
end

# Speficic method for filter operator over SingleObservable
function on_call!(::Type{L}, ::Type{L}, operator::FilterOperator, source::SingleObservable{L}) where L
    if operator.filterFn(source.value)
        return of(source.value)
    else
        return completed(L)
    end
end

# Specific method for combineLatest operator over SingleObservable
function combineLatest(source1::SingleObservable{S1}, source2::SingleObservable{S2}) where S1 where S2
    return SingleObservable{Tuple{S1, S2}}((source1.value, source2.value))
end

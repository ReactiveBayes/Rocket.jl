export on_call!
export combineLatest

# TODO: WIP
# TODO: Untested and undocumented

# Speficic method for map operator over SingleObservable
function on_call!(::Type{L}, ::Type{R}, operator::MapOperator{R}, source::SingleObservable{L}) where L where R
    return of(convert(R, operator.mappingFn(source.value)))
end

# Speficic method for filter operator over SingleObservable
function on_call!(::Type{L}, ::Type{L}, operator::FilterOperator, source::SingleObservable{L}) where L
    if operator.filterFn(source.value)
        return of(source.value)
    else
        return completed(L)
    end
end

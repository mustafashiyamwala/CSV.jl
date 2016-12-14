### Parsing utilities

macro chk1(expr,label=:error)
    quote
        x = $(esc(expr))
        if isnull(x[1])
            @goto $label
        else
            get(x[1]),x[2]
        end
    end
end

@inline function tryparsenext_base10_digit(T,str,i, len)
    R = Nullable{T}
    i > len && @goto error
    c,ii = next(str,i)
    '0' <= c <= '9' || @goto error
    return R(c-'0'), ii

    @label error
    return R(), i
end

@inline function tryparsenext_base10(T, str,i,len, maxdig)
    R = Nullable{T}
    r,i = @chk1 tryparsenext_base10_digit(T,str,i, len)
    ten = T(10)
    for j = 2:maxdig
        d,i = @chk1 tryparsenext_base10_digit(T,str,i,len) done
        r = r*ten + d
    end
    @label done
    return R(r), i

    @label error
    return R(), i
end

@inline function tryparsenext_sign(str, i, len)
    R = Nullable{Int}
    i > len && return R(), i
    c, ii = next(str, i)
    if c == '-'
        return R(-1), ii
    else
        '0' <= c <= '9' ? (R(1), i) : (R(), i)
    end
end

@inline function tryparsenext_base10_frac(str,i,len,maxdig)
    R = Nullable{Int}
    r,i = @chk1 tryparsenext_base10_digit(Int, str,i,len)
    for j = 2:maxdig
        nd,i = tryparsenext_base10_digit(Int, str,i,len)
        if isnull(nd)
            for k = j:maxdig
                r *= 10
            end
            break
        end
        d = get(nd)
        r = 10*r + d
    end
    return R(r), i

    @label error
    return R(), i
end

@inline function tryparsenext_char(str,i,len,cc::Char)::Tuple{Nullable{Char},Int}
    R = Nullable{Char}
    i > len && @goto error
    c,ii = next(str,i)
    c == cc || @goto error
    return R(c), ii

    @label error
    return R(), i
end

@inline function tryparsenext_string{N}(str, i, len, endchars::NTuple{N, Char}, maxchars=typemax(Int))
    for j=1:maxchars
        i > len && break
        c, ii = next(str, i)
        for endchar in endchars
            endchar == c && break
        end
        i = ii
    end
    return Nullable{Int}(0), i
end

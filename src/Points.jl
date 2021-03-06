module Points

export Point, get_x, get_y, get_z, get_coords, unit_vectors2, unit_vectors3
export UnitVector, Biased, Unbiased

###
### Point
###

struct Point{N, T}
    coords::NTuple{N, T}
end

get_coords(p::Point) = p.coords
Point(coords::T...) where T = Point{length(coords), T}(coords)
Point(coords::Tuple) = Point(coords...)

@generated function Point{N, T}() where {N, T}
    isa(N, Integer) || throw(TypeError(:Point, "", Integer, typeof(N)))
    N > 0 || throw(DomainError(N, "N must be a positive Integer"))
    return Point((zero(T) for i in 1:N)...,)
end

Point{N}() where {N} = Point{N, Float64}()
Point() = Point{1}()

Base.getindex(p::Point, inds...) = getindex(get_coords(p), inds...)
Base.length(p::Point) = length(get_coords(p))
Base.eltype(p::Point) = eltype(get_coords(p))

get_x(p::Point) = p[1]
get_y(p::Point) = p[2]
get_z(p::Point) = p[3]

import Base: +, -, *, ==
+(p::Point{1, <:Any}, x::Number) = Point(x + get_x(p))
+(p1::Point{N}, p2::Point{N}) where N = Point((get_coords(p1) .+ get_coords(p2))...)
*(p1::Point, n::Number) = Point((get_coords(p1) .* n))
*(n::Number, p::Point) = p * n
-(p::Point) = Point(broadcast(-, get_coords(p))...)
-(p1::Point{N}, p2::Point{N}) where N = p1 + (-p2)
==(p1::Point{N}, p2::Point{N}) where N = get_coords(p1) == get_coords(p2)
norm_squared(p::Point) = sum(x -> x^2, p.coords)

Base.zero(p::Point) = Base.zero(typeof(p))
Base.zero(::Type{Point{N, T}}) where {T, N} = Point{N, T}()
Base.iszero(p::Point{N, T}) where {N, T} = p == Point{N, T}()
Base.show(io::IO, p::Point{N, T}) where {T, N}  = print(io, "Point{$N, $T}", get_coords(p))
Base.show(io::IO, p::Point{1, T}) where {T}  = print(io, "Point{1, $T}(", get_coords(p)[1], ")")

const unit_vectors1 = (Point(1), Point(-1))

const unit_vectors2 = (Point(0, 1), Point(1, 0), Point(0, -1), Point(-1, 0))

const unit_vectors3 = (Point(0, 0, 1), Point(0, 1, 0), Point(1, 0, 0),
                       Point(0, 0, -1), Point(0, -1, 0), Point(-1, 0, 0))

struct UnitVector{P} end

struct Biased
    bias::Float64
    cutoff::Float64
end
Biased(bias=0.0) = Biased(bias, 1/2 + bias)

struct Unbiased end

Base.rand(ub::Unbiased, t::Type{UnitVector{Point{N, T}}}) where {N, T} = rand(t)
Base.rand(::Type{UnitVector{Point{N, T}}}) where {N, T} = rand(UnitVector{Point{N}})
Base.rand(::Type{UnitVector{Point{1}}}) = rand(Bool) ? Point(1) : Point(-1)
Base.rand(::Type{UnitVector{Point{2}}}) = unit_vectors2[rand(1:4)]
Base.rand(::Type{UnitVector{Point{3}}}) = unit_vectors3[rand(1:6)]
Base.rand(b::Biased, ::Type{UnitVector{Point{N, T}}}) where {N, T} = rand(b, UnitVector{Point{N}})
Base.rand(b::Biased, ::Type{UnitVector{Point{1}}}) = rand() > b.cutoff ? Point(1) : Point(-1)

end # module Point

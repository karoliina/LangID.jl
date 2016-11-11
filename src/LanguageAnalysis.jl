module LanguageAnalysis

"""
Concatenate the given array of sparse vectors into a dense matrix, such that the vectors form the columns of
the matrix.
"""
function sparsecat{T}(v::Array{SparseVector{T,Int64},1})
    # ensure all the sparse vectors have equal length
    n = length(v)
    m = maximum([x.n for x in v])
    for i=1:n
        v[i] = sparsevec(v[i].nzind, v[i].nzval, m)
    end

    # construct the dense matrix from the sparse vectors
    A = zeros(T, m, n)
    for i=1:m
        for j=1:n
            if v[j][i] != 0
                A[i,j] = v[j][i]
            end
        end
    end

    return A
end

end # module

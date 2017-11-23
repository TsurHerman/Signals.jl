using Compat
try
    using Test
catch
    using Base.Test
end

using Signals
using Signals: state

if VERSION >= v"0.7.0"
    Pkg.checkout("BenchmarkTools")
end

include("push_pull.jl")
include("benchmark.jl")
include("operators.jl")
include("binding.jl")
include("time.jl")

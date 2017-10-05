try
    using Test
catch
    using Base.Test
end

using Proactive

include("push_pull.jl")
include("benchmark.jl")
include("modifiers.jl")

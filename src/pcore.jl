
function nop()
    nothing
end
mutable struct Signal{F,ARGS}
    data
    f::F
    args::ARGS
    children::Vector{Signal}
    data_age::Int
end

Signal(val) = begin
    s = Signal(val,nop,(),Signal[],0)
end

Signal(f::Function,args...) = begin
    s = Signal(nothing,f,args,Signal[],0)
    for arg in args
        isa(arg,Signal) && push!(arg.children,s)
    end
    s
end

function value(s::Signal)
    s.data
end
value(s) = s

import Base.getindex
function getindex(s::Signal)
    value(s)
end

function set_value!(s::Signal,val)
    s.data_age += 1
    s.data = val
end

#push!
(s::Signal)(val) = push!(s,val)
import Base.push!
function push!(s::Signal,val)
    set_value!(s,val)
    foreach(push!,s.children)
end

function push!(s::Signal)
    push!(s,action_on_value(s))
end

function action_on_value(s::Signal)
    s.f(map(value,s.args)...)
end

#pull!
function pull!(s::Signal)
    set_value!(s,action_on_pull(s))
    value(s)
end
pull!(s) = s

function action_on_pull(s::Signal)
    s.f(map(pull!,s.args)...)
end

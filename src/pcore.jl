
function nop()
    nothing
end

mutable struct Signal{F}
    data
    act_on::F
    children::Vector{Signal}
    data_valid::Bool
end

const SourceSignal() = typeof(Signal(nothing))

Signal(val) = begin
    s = Signal(val,() -> val,Signal[],true)
    s
end

Signal(f::Function,args...) = begin
    g(trans::Function) = f(map(trans,args)...)
    s = Signal(g(value),g,Signal[],true)
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

import Base.getindex
function getindex(s::Signal,val)
    set_value!(s,val)
end

function set_value!(s::Signal,val)
    s.data_valid = true
    foreach(invalidate!,s.children)
    s.data = val
end

function invalidate!(s::Signal)
    s.data_valid = false
    foreach(invalidate!,s.children)
end

#push!
(s::Signal)(val) = push!(s,val)
import Base.push!
function push!(s::Signal,val)
    set_value!(s,val)
    propogate!(s)
    val
end

function propogate!(s::Signal)
    foreach(pull!,s.children)
    foreach(propogate!,s.children)
end

#pull!
(s::Signal)() = pull!(s)

function pull!(s::Signal)
    if !valid(s)
        s.data_valid = true
        s.data = action(s,pull!)
    end
    return value(s)
end
pull!(s) = s


#wizardry
valid(s) = true
valid(s::Signal) = s.data_valid

function action(s::Signal,trans::Function)
    s.act_on(trans)
end

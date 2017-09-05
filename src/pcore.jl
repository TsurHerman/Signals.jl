
function nop()
    nothing
end
mutable struct Signal{F}
    data
    act_on::F
    children::Vector{Signal}
    data_age::Int
end

const EmptySignal() = typeof(Signal(nothing))

Signal(val) = begin
    s = Signal(val,nop,Signal[],0)
end

Signal(f::Function,args...) = begin
    g(trans::Function) = f(map(trans,args)...)
    s = Signal(g(value),g,Signal[],0)
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
    val
end

function push!(s::Signal)
    push!(s,action(s,value))
    value(s)
end

#pull!
(s::Signal)() = pull!(s)
function pull!(s::Signal)
    pull!(s,action(s,value))
    value(s)

    # set_value!(s,action(s,pull!))
    # value(s)
end

function pull!(s::Signal,val)
    set_value!(s,val)
    value(s)
end
pull!(s) = s


#wizardry
function action(s::EmptySignal(),::Function)
    value(s)
end

function action(s::Signal,trans::Function)
    s.act_on(trans)
end

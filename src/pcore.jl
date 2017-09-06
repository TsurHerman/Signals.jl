
function nop()
    nothing
end

const age = Ref(0)
world_age() = begin global age;age.x;end
world_age(inc::Int) = begin global age; (age.x += inc);end
export age

mutable struct Signal{F}
    data
    act_on::F
    children::Vector{Signal}
    data_world_age::Int
end

const SourceSignal() = typeof(Signal(nothing))

Signal(val) = begin
    s = Signal(val,nop,Signal[],world_age())
    s
end

Signal(f::Function,args...) = begin
    g(trans::Function) = f(map(trans,args)...)
    s = Signal(g(value),g,Signal[],world_age())
    for arg in args
        isa(arg,Signal) && push!(arg.children,s)
    end
    s
end

world_age(s::Signal) = s.data_world_age
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
    s.data_world_age = world_age(1)
    s.data = val
end

#push!
(s::Signal)(val) = push!(s,val)
import Base.push!
function push!(s::Signal,val)
    set_value!(s,val)
    foreach(pull!,s.children)
    foreach(push!,s.children)
    val
end

function push!(s::Signal)
    s.data_world_age = world_age()
    foreach(s.children) do child
        if child.data_world_age < world_age()
            pull!(child)
        end
    end
    value(s)
end

#pull!
(s::Signal)() = pull!(s)

function pull!(s::Signal)
    if s.data_world_age == world_age()
        return s.data
    end
    foreach(pull!,s.act_on.args)
    s.data_world_age = world_age()
    return s.data = action(s,value)
end
pull!(s) = s


#wizardry
function pull!(s::SourceSignal())
    if s.data_world_age == world_age()
        return s.data
    end
    s.data_world_age = world_age()
    return s.data = action(s,value)
end

function action(s::SourceSignal(),::Function)
    value(s)
end

function action(s::Signal,trans::Function)
    s.act_on(trans)
end

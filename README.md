# Signals

[![Build Status](https://travis-ci.org/TsurHerman/Signals.jl.svg?branch=master)](https://travis-ci.org/TsurHerman/Signals.jl)[![codecov.io](http://codecov.io/github/TsurHerman/Signals.jl/coverage.svg?branch=master)

Signals provides a multi-paradigm fast functional reactive programing for julia.
It supports both pull and push operations and async(default) and non-async modes.

It was largely influenced from [Reactive](https://github.com/JuliaGizmos/Reactive.jl), but takes a different approach on some key factors.

For a quick introduction into reactive programming and signals using julia , see:
[Reactive tutorial](http://juliagizmos.github.io/Reactive.jl/)

## Signal Creation
```julia
S = Signal(val;strict_push = false)
```
Create a source `Signal` with initial value `val`, setting
`strict_push` to `true` guarantees that every push to this `Signal`
will be carried out independently. otherwise if updates occur faster than what the `eventloop`
can process, then only the last value before the `eventloop` kicks in will be used(*default*)

```julia
S = Signal(f,args...)
```

Creates a derived `Signal` who's value is `f(args...)` , args can be of any type,
`Signal` args get replaced by their value before calling `f(args...)`. reads best with
with `do` notation(see example).

## Syntax

`S[] = val`

sets the value of `S` to `val` without propagating the change to the rest of the signal graph,
useful in pull based paradigm

`S()`

`pull!` Signal, pulling any changes in the Signal graph that affects `S`

`S(val)

sets the value of `S` to `val` and pushes the changes along the Signal graph

`S[]`

gets the current value stored in `S` without pulling changes from the graph
## Example
```julia
julia> A = Signal(1) #source Signal
Signal
value: 1

julia> B = 2 #non-Signal input
2

julia>  C = Signal(A,B) do a,b #derived Signal
            a+b
        end

Signal
value: 3

julia> A[] = 10 # set value without propagation
10
julia> C[] # reads current value
3
julia> C() # pull latest changes from the Signal graph
12
julia> A(100) # set value to a signal and propagate this change
100
julia> C[]
102
```

## Operators
Signals supports several reactive operators
 * `droprepeats`
 * `when`
 * `filter`
 * `sampleon`
 * `foldp`
 * `count`
 * `prev`
 * `merge`
 * `async_signal`
 * `remote_signal`
 * `bind!`
 * `unbind!`


individual documentation files are available from within `julia`

## Time operators
Signals supports several operators that takes time into consideration, for example `debounce` which executes only after a set amount of time has passed since the inputs were updated or `throttle` which creates a `Signal` that is guaranteed not to   
be executed more than set amount of times per second.
* `debounce`
* `throttle`
* `for_signal`
* `fps`
* `every`
* `buffer`

## Async mode
By default Signals run asynchronically in a dedicated `eventloop`, this behavior can be changed using
```julia
Signals.async_mode(false)
```
or by individual non-async pushes to the signal graph using:
```julia
push!(s,val,false)
```

## Dynamic
Signals is dynamic , one can push values of any type to a source signal
```julia
julia> using Signals
julia> A = Signal(1)
Signal  
value: 1

julia> B = Signal(A,A) do a,b
       a*b
       end
Signal  
value: 1

julia> A(rand(3,3));
julia> B()
3×3 Array{Float64,2}:
 0.753217  0.796031  0.265298
 0.28489   0.209641  0.249161
 0.980177  0.810512  0.571937
```

## Fast
Signals package was rigorously optimized for speed of execution
and minimal recalculation of signal graph updates, it achieves around `2x`-`4x` speedup over the current sate of the art functional reactive programming for julia

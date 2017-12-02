"""
    s = buffer(input; buf_size = Inf, timespan = 1, type_stable = false)

Create a signal whos buffers updates to signal `input` until maximum size of `buf_size`
or until `timespan` seconds have passed. The signal value is the last full buffer emitted
or an empty vector if the buffer have never been filled before.

Buffer type will be `Any` unless `type_stable` is set to `true`, then it will be set
to the value of the first encountered item.
"""

function buffer(input; buf_size = Inf, timespan = 1, type_stable = false)
    _buf = type_stable ? typeof(input())[] : Any[]
    sbuf = foldp(push!,_buf,input)
    cond = Signal(sbuf;state = time()) do in,state
        last_update = state.x
        (time() - last_update > timespan) || (length(in) >= buf_size)
    end
    when(cond,sbuf; v0 = _buf) do buf
        state(cond,time())
        frame = copy(buf)
        empty!(_buf)
        frame
    end

end
export buffer

"""
    debounce(f, args...; delay = 1, v0 = nothing)

Create a `Signal` whos action `f(args...)` will be called only after `delay` seconds
have passed since the last time its `args` were updated. Only works in push based paradigm.
If `v0` is not specified then the initial value is `f(args...)`.
"""
function debounce(f,args...;delay = 1 , v0 = nothing)
    timer = Timer(identity,0)
    f_args = PullAction(f,args)
    debounced_signal = Signal(v0 == nothing ? f_args() : v0)
    Signal(args...) do args
        finalize(timer)
        timer = Timer(t->debounced_signal(f_args()),delay)
    end
    debounced_signal
end
export debounce

abstract type Throttle <: PullType end
"""
    throttle(f::Function, args...; maxfps = 0.03)

Create a throttled `Signal` whos action `f(args...)` will be called only
if `1/maxfps` time has passed since the last time it updated. The resulting `Signal`
will be updated maximum of `maxfps` times per second.
"""
function throttle(f::Function,args... ; maxfps = 30)
    pa = PullAction(f,args,Throttle)
    sd = SignalData(pa())
    state = Ref((1/maxfps,time()))
    Signal(sd,pa,state)
end
export throttle

function (pa::PullAction{Throttle,A})(s) where A
    (dt,last_update) = s.state.x
    args = pull_args(pa)
    if !valid(s)
        if time() - last_update < dt
            validate(s)
        else
            s.state.x = (dt,time())
            pa()
        end
    end
    value(s)
end

function activate_timer(s,dt,duration)
    signalref = WeakRef(Ref(s))
    start_time = time()
    t = Timer(dt,dt) do t
        time_passed = time() - start_time
        if time_passed > duration || signalref.value == nothing
            finalize(t)
        else
            push!(signalref.value.x,time(),true)
        end
        nothing
    end
    t
end

"""
    s = every(dt; duration = Inf)

A signal that updates every `dt` seconds to the current timestamp, for `duration` seconds.
"""
function every(dt;duration  = Inf)
    res = Signal(time())
    activate_timer(res,dt,duration)
    res
end
export every

"""
    s = fps(freq; duration = Inf)

A signal that updates `freq` times a second to the current timestamp, for `duration` seconds.
"""
function fps(freq;duration  = Inf)
    every(1/freq; duration = duration)
end
export fps

"""
    s = fpswhen(switch::Signal, freq; duration = Inf)

A signal that updates 'freq' times a second to the current timestamp, for `duration` seconds
if and only if the value of `switch` is `true`.
"""
function fpswhen(switch::Signal,freq; duration = Inf)
    res = Signal(time())
    timer = Timer(0)
    Signal(droprepeats(switch)) do sw
        if sw == true
            timer = activate_timer(res,1/freq,duration)
        else
            finalize(timer)
        end
    end
    res
end
export fpswhen

"""
     s = for_signal(f::Function, range, args...; fps = 1)

Create a `Signal` that updates to `f(i,args....) for i in range` every `1/fps` seconds.
`range` and `args` can be of type `Signal` or any other type. The loop starts whenever
one of the arguments or when `range` itself updates. If the previous for loop did not
complete it gets cancelled.

# Examples

    range = Signal(1:5)
    A = Signal(2)
    for_signal(range,A;fps = 30) do i,a
        println(a^i)
    end
"""
function for_signal(f::Function,range,args...;fps = 1)
    i_sig = Signal(first(pull!(range)))
    timer = Timer(0)
    Signal(args...;v0 = timer) do args
        current_range = pull!(range)
        finalize(timer)
        state = Ref(start(current_range))
        (item,state.x ) = next(current_range,state.x)
        i_sig(item)
        timer = Timer(1/fps,1/fps) do t
            if done(current_range,state.x)
                finalize(t)
            else
                (item,state.x ) = next(current_range,state.x)
                i_sig(item)
            end
            nothing
        end
    end
    Signal(i_sig) do i
        f(i,pull_args(args)...)
    end
end
export for_signal


nothing

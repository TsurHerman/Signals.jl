
using DataStructures
world_age() = ccall(:jl_get_world_counter,Int,())
const global pull_queue = Queue(Signal)
const global push_queue = Queue(Tuple{Signal,Any})
const global eventloop_cond = Condition()

function empty_queues()
    empty!(pull_queue.store)
    empty!(push_queue.store)
end
function get_current_queue(q::Queue{T}) where T
    res = [x for x in q]
    empty!(q.store)
    res
end


function __init__()
    @schedule eventloop()
end

function process_pulls()
    if !isempty(pull_queue)
        foreach(pull!,get_current_queue(pull_queue))
        process_pushs()
    end
end

function run_till_now()
    while !isempty(pull_queue)
        foreach(pull!,pull_queue)
        empty!(pull_queue.store)
        if !isempty(push_queue)
            SV = dequeue!(push_queue)
            soft_push!(SV[1],SV[2])
        end
    end
end

#make those pushs aware that they are to be executed in an order blocking way
function process_pushs()
    println("processing pushs")
    if !isempty(push_queue)
        #Push in a preserving way , async because we are already in the event loop
        foreach(get_current_queue(push_queue)) do SV
            strict_push!(SV[1],SV[2])
        end
        process_pulls()
    end
end

function eventloop(eventloop_world_age = world_age())
    try while true
        if !isempty(pull_queue)
            if world_age() > eventloop_world_age
                debug_mode() && println("restarting Signals eventloop")
                @schedule eventloop()
                break
            end
            run_till_now()
        end
        wait(eventloop_cond)
    end catch e
        empty_queues()
        @schedule eventloop()
        rethrow(e)
        # @schedule eval(Main,:(error("Signal Error")))
    end
end

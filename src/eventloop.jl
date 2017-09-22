
using DataStructures
world_age() = ccall(:jl_get_world_counter,Int,())
const global pull_queue = Queue(Signal)
const global push_queue = Queue(Tuple{Signal,Any})
const global eventloop_cond = Condition()

function empty_queues()
    empty!(pull_queue.store)
    empty!(push_queue.store)
end

function __init__()
    @schedule eventloop()
end

function process_pulls()
    if !isempty(pull_queue)
        foreach(pull!,pull_queue)
        process_pushs()
    end
end

function run_till_now()
    process_pulls()
end

#make those pushs aware that they are to be executed in an order blocking way
function process_pushs()
    if !isempty(push_queue)
        #Push in a preserving way , async because we are already in the event loop
        foreach(push_queue) do SV
            strict_push!(SV[1],SV[2],true)
        end
        process_pulls()
    end
end

function eventloop(eventloop_world_age = world_age())
    try while true
        if !isempty(pull_queue)
            if world_age() > eventloop_world_age
                println("restarting proactive eventloop")
                @schedule eventloop()
                break
            end
            process_pulls()
        end
        wait(eventloop_cond)
    end catch e
        empty_queues()
        @schedule eventloop()
        # rethrow(e)
        throw(ErrorException("fff"))
        # @schedule eval(Main,:(error("Signal Error")))
    end
end

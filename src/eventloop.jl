
using DataStructures
world_age() = ccall(:jl_get_world_counter,Int,())
const global pull_queue = Queue(Signal)
const global push_queue = Queue(Signal)
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
        foreach(push!,push_queue)
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

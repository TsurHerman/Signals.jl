using DataStructures
world_age() = ccall(:jl_get_world_counter, Int, ())
const global pull_queue = Queue{Signal}()
const global push_queue = Queue{Tuple{Signal, Any}}()
const global eventloop_cond = Condition()


function empty_queues()
    empty!(pull_queue.store)
    empty!(push_queue.store)
end

function __init__()
    @async eventloop()
end


function run_till_now()
    while !isempty(pull_queue)
        foreach(pull!, pull_queue)
        empty!(pull_queue.store)
        if !isempty(push_queue)
            (s, val) = dequeue!(push_queue)
            soft_push!(s, val)
        end
    end
end

function eventloop(eventloop_world_age = world_age())
    try
        while true
            if !isempty(pull_queue)
                if world_age() > eventloop_world_age
                    debug_mode() && println("restarting Signals eventloop")
                    @async eventloop()
                    break
                end
                debug_mode() && println("pull-queue length: $(length(pull_queue))")
                run_till_now()
            end
            wait(eventloop_cond)
        end
    catch e
        st = stacktrace(catch_backtrace())
        empty_queues()
        @async eventloop()
        showerror(stderr, SignalException(e,st))
    end
end

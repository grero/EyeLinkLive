module EyelinkLive
using Eyelink
using StaticArrays
#TODO: Make this more general
_path = "/Library/Frameworks/eyelink_core.framework/Versions/Current/"
if !(_path in Libdl.DL_LOAD_PATH)
  push!(Libdl.DL_LOAD_PATH, "/Library/Frameworks/eyelink_core.framework/Versions/Current/")
end


"""
Open a connection to eyelink. `Mode` decides the type of connection
"""
open_connection(mode::Int16) = ccall((:open_eyelink_connection, "eyelink_core"), Int16, (Int16,), mode)

open_broadcast_connection() = ccall((:eyelink_broadcast_open, "eyelink_core"), Int16, ())

function open_broadcast_connection(addr::IPv4)
  #initialize the dll
  ret = ccall((:set_eyelink_address, "eyelink_core"), Int16, (Cstring,), string(addr))
  if ret != 0
    return -1
  end
  open_broadcast_connection()
end

function get_newest_sample()
  sample = Eyelink.FSAMPLE()
  get_newest_sample(sample)
end

function get_newest_sample!(sample::Eyelink.FSAMPLE)
  ret = ccall((:eyelink_newest_float_sample, "eyelink_core"), Int16, (Ptr{Void},),C_NULL)
  if ret > 0
    ret = ccall((:eyelink_newest_float_sample, "eyelink_core"), Int16, (Ptr{Eyelink.FSAMPLE},),sample)
  end
  sample
end

"""
Continuously collect saccade velocity by listening for `ENDSACC` events
"""
function get_saccade_velocity(pvel::Observable{Float64})
    ev = Ref{FEVENT}(zero(FEVENT))
    saccades = Matrix{Float64}[]
    while true
        ii = ccall((:eyelink_get_next_data, "eyelink_core"), Int16, (Ptr{Void},), C_NULL)
        if ii == datatypes[:endsacc]
            ccall((:eyelink_get_data_data, "eyelink_core"), Int16, (Ref{FEVENT},), ev)
            pvel[] = ev.pvel
        end
    end
end

"""
Listen for message events from eyelink
"""
function get_message_event(msg::Observable{Tuple{UInt32, String}})
    ev = Ref{FEVENT}(zero(FEVENT))
    while true
        ii = ccall((:eyelink_get_next_data, "eyelink_core"), Int16, (Ptr{Void},), C_NULL)
        if ii == datatypes[:messageevent]
            ccall((:eyelink_get_data_data, "eyelink_core"), Int16, (Ref{FEVENT},), ev)
            msg[] = (ev.time, unsafe_string(convert(Ptr{UInt8}, ev.message + sizeof(UInt16)), ev.message.length))
        end
    end
end

"""
Get the first saccade after the response cue
"""
function get_response_saccade(pvel::Observable{Float64}, trigger::String="00000101")
    response_on = false
    saccade_seen = false
    while true
        ii = ccall((:eyelink_get_next_data, "eyelink_core"), Int16, (Ptr{Void},), C_NULL)
        if ii == datatypes[:messageevent] & !response_on
            msg = unsafe_string(convert(Ptr{UInt8}, ev.message + sizeof(UInt16)), ev.message.length)
            msg = replace(msg, " " => "")
            if msg == trigger
                response_on = true
                saccade_seen = false
            end
        elseif ii == datatypes[:endsacc] & response_on & !saccade_seen
            ccall((:eyelink_get_data_data, "eyelink_core"), Int16, (Ref{FEVENT},), ev)
            saccade_seen = true
            response_on = false
            pvel[] = ev.pvel
        end
    end
end

end  # module

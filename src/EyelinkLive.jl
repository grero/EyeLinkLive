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

open_broadcast_connection = ccall((:eyelink_broadcast_open, "eyelink_core"), Int16, ())

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
end  # module

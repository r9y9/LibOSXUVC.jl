module LibOSXUVC

export UVCParams, uvcparams_set

deps = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("LibOSXUVC not properly installed. Please run Pkg.build(\"LibOSXUVC\")")
end

const version = convert(VersionNumber,
    bytestring(ccall((:osxuvc_version, libosxuvc), Ptr{Cchar}, ())))

type UVCParams
    locationId::Ptr{Cchar}
    interfaceIndex::Cint
    processingUnitId::Cint
    autoFocus::Bool
    focusValue::Cfloat
    autoExposure::Bool
    exposureValue::Cfloat
    autoWhitebalance::Bool
    whitebalanceValue::Cfloat
    autoFrequency::Bool
    frequency::Cint

    function UVCParams()
        new(pointer("0x00"), 0x02, 0x02,
            true, 0.0, # focus
            true, 0.0, # exposure
            true, 0.0, # whiteblance
            true, 50)  # frequency
    end
end

function uvcparams_set(params::UVCParams)
    ccall((:osxuvc_uvcparams_set, libosxuvc), Void, (Ref{UVCParams},), params)
end

end # module

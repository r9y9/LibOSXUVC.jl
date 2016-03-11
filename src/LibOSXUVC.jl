module LibOSXUVC

export
    UVCVideoInterfaceConfigurationParams,
    UVCCameraControl,
    UVCControlType,
    setupByLocationId,
    setBoolValue,
    getBoolValue,
    setNormalizedValue,
    getNormalizedValue

deps = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("LibOSXUVC not properly installed. Please run Pkg.build(\"LibOSXUVC\")")
end

const version = convert(VersionNumber,
    bytestring(ccall((:osxuvc_version, libosxuvc), Ptr{Cchar}, ())))

type UVCVideoInterfaceConfigurationParams
    interfaceIndex::UInt16
    processingUnitId::UInt16
end

type UVCCameraControl
    handle::Ptr{Void}

    function UVCCameraControl(params::UVCVideoInterfaceConfigurationParams)
        handle = ccall((:OSXUVCCreateUVCCameraControl, libosxuvc),
            Ptr{Void},
            (Ref{UVCVideoInterfaceConfigurationParams},), params)
        p = new(handle)
        finalizer(p, obj -> ccall((:OSXUVCDestroyUVCCameraControl, libosxuvc),
            Void,
            (Ptr{Void},), obj.handle))
        p
    end
end

# should be in sync with uvc_control_type_t
module UVCControlType

const AutoExposure = 0
const AbsoluteExposure = 1
const AutoFocus = 2
const AbsoluteFocus = 3
const AutoWhitebalance = 4
const AbsoluteWhitebalance = 5
const Gain = 6
const Brightness = 7
const Contrast = 8
const Saturation = 9
const Sharpness = 10
const PowerLineFrequency = 11

end

function setupByLocationId(ucc::UVCCameraControl, locationId::AbstractString)
    intLocatiionId = ccall(
        (:OSXUVCUVCConvertLocationIdStringToUInt32, libosxuvc),
        UInt32, (Ptr{Cchar},), pointer(locationId))
    ccall((:OSXUVCCUVCCameraControlSetupByLocationId, libosxuvc),
        Bool, (Ptr{Void}, UInt32), ucc.handle, intLocatiionId)
    ucc
end

# convenient constructor
function UVCCameraControl(params::UVCVideoInterfaceConfigurationParams,
        locationId::AbstractString)
    ucc = UVCCameraControl(params)
    setupByLocationId(ucc, locationId)
    ucc
end

### set/get ###

function setBoolValue(ucc::UVCCameraControl, typ, val::Bool)
    ccall((:OSXUVCCUVCCameraControlSetBoolValue, libosxuvc),
        Bool, (Ptr{Void}, Cint, Bool), ucc.handle, typ, val)
end

function getBoolValue(ucc::UVCCameraControl, typ)
    val = Bool[1]
    ccall((:OSXUVCCUVCCameraControlGetBoolValue, libosxuvc),
        Bool, (Ptr{Void}, Cint, Ptr{Bool}), ucc.handle, typ, pointer(val))
    val[1]
end


function setNormalizedValue(ucc::UVCCameraControl, typ, val)
    ccall((:OSXUVCCUVCCameraControlSetNormalizedValue, libosxuvc),
        Bool, (Ptr{Void}, Cint, Cfloat), ucc.handle, typ, val)
end

function getNormalizedValue(ucc::UVCCameraControl, typ)
    val = Cfloat[1]
    ccall((:OSXUVCCUVCCameraControlGetNormalizedValue, libosxuvc),
        Bool, (Ptr{Void}, Cint, Ptr{Cfloat}), ucc.handle, typ, pointer(val))
    val[1]
end

### utils ###

function Base.dump(ucc::UVCCameraControl)
    ccall((:OSXUVCUVCCameraControlDumpConfiguration, libosxuvc),
        Void, (Ptr{Void},), ucc.handle)
end

end # module

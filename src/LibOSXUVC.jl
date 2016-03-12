module LibOSXUVC

export
    UVCVideoInterfaceParams,
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
    bytestring(ccall((:OSXUVCVersion, libOSXUVC), Ptr{Cchar}, ())))

type UVCVideoInterfaceParams
    interfaceIndex::UInt16
    processingUnitId::UInt16
end

type UVCCameraControl
    handle::Ptr{Void}

    function UVCCameraControl(params::UVCVideoInterfaceParams)
        handle = ccall((:OSXUVCUVCCameraControlCreate, libOSXUVC),
            Ptr{Void},
            (Ref{UVCVideoInterfaceParams},), params)
        p = new(handle)
        finalizer(p, obj -> ccall((:OSXUVCUVCCameraControlDestroy, libOSXUVC),
            Void,
            (Ptr{Void},), obj.handle))
        p
    end
end

module UVCControlType

import ..LibOSXUVC: libOSXUVC

min_control_type = ccall((:UVCGetMinControlType, libOSXUVC), Cint,())
max_control_type = ccall((:UVCGetMaxControlType, libOSXUVC), Cint,())
for v in min_control_type:max_control_type
    name = ccall((:UVCGetControlTypeString, libOSXUVC),
            Ptr{Cchar}, (Int32,), v) |> bytestring |> symbol
    @eval const $name = $v
end

end

function setupByLocationId(ucc::UVCCameraControl, locationId::AbstractString)
    intLocatiionId = ccall(
        (:OSXUVCConvertLocationIdStringToUInt32, libOSXUVC),
        UInt32, (Ptr{Cchar},), pointer(locationId))
    ccall((:OSXUVCUVCCameraControlSetupByLocationId, libOSXUVC),
        Bool, (Ptr{Void}, UInt32), ucc.handle, intLocatiionId)
    ucc
end

# convenient constructor
function UVCCameraControl(params::UVCVideoInterfaceParams,
        locationId::AbstractString)
    ucc = UVCCameraControl(params)
    setupByLocationId(ucc, locationId)
    ucc
end

### set/get ###

function setBoolValue(ucc::UVCCameraControl, typ, val::Bool)
    ccall((:OSXUVCUVCCameraControlSetBoolValue, libOSXUVC),
        Bool, (Ptr{Void}, Cint, Bool), ucc.handle, typ, val)
end

function getBoolValue(ucc::UVCCameraControl, typ)
    val = Bool[1]
    ccall((:OSXUVCUVCCameraControlGetBoolValue, libOSXUVC),
        Bool, (Ptr{Void}, Cint, Ptr{Bool}), ucc.handle, typ, pointer(val))
    val[1]
end


function setNormalizedValue(ucc::UVCCameraControl, typ, val)
    ccall((:OSXUVCUVCCameraControlSetNormalizedValue, libOSXUVC),
        Bool, (Ptr{Void}, Cint, Cfloat), ucc.handle, typ, val)
end

function getNormalizedValue(ucc::UVCCameraControl, typ)
    val = Cfloat[1]
    ccall((:OSXUVCUVCCameraControlGetNormalizedValue, libOSXUVC),
        Bool, (Ptr{Void}, Cint, Ptr{Cfloat}), ucc.handle, typ, pointer(val))
    val[1]
end

### utils ###

function Base.dump(ucc::UVCCameraControl)
    ccall((:OSXUVCUVCCameraControlDump, libOSXUVC),
        Void, (Ptr{Void},), ucc.handle)
end

end # module

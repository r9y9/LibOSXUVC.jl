module LibOSXUVC

export
    UVCVideoInterfaceParams,
    UVCControlInfo,
    UVCRange,
    UVCCameraControl,
    UVCControlType,
    setupByLocationId,
    setBoolValue,
    getBoolValue,
    setNormalizedValue,
    getNormalizedValue,
    getControlInfo,
    getRangeForControl

deps = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("LibOSXUVC not properly installed. Please run Pkg.build(\"LibOSXUVC\")")
end

const version = convert(VersionNumber,
    bytestring(ccall((:OSXUVCVersion, libOSXUVC), Ptr{Cchar}, ())))

macro uvccall(f, rettype, argtypes, args...)
    args = map(esc, args)
    quote
        r = ccall(($f, LibOSXUVC.libOSXUVC),
              $rettype, $argtypes, $(args...))
        if r != Void && r != 0
            error("[OSXUVC]: failed in $($f), code: $r")
        end
        r
    end
end

type UVCVideoInterfaceParams
    interfaceIndex::UInt16
    processingUnitId::UInt16
end

type UVCControlInfo
    size::UInt16
    selector::UInt16
    unit::UInt16
end

type UVCRange
    min::Cint
    max::Cint
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
    @uvccall(:OSXUVCUVCCameraControlSetupByLocationId,
        Cint, (Ptr{Void}, UInt32), ucc.handle, intLocatiionId)
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

function setBoolValue(ucc::UVCCameraControl, typ, val)
    @uvccall(:OSXUVCUVCCameraControlSetBoolValue,
        Cint, (Ptr{Void}, Cint, Cint), ucc.handle, typ, val)
end

function getBoolValue(ucc::UVCCameraControl, typ)
    val = Cint[1]
    @uvccall(:OSXUVCUVCCameraControlGetBoolValue,
        Cint, (Ptr{Void}, Cint, Ptr{Cint}), ucc.handle, typ, pointer(val))
    val[1]
end


function setNormalizedValue(ucc::UVCCameraControl, typ, val)
    @uvccall(:OSXUVCUVCCameraControlSetNormalizedValue,
        Cint, (Ptr{Void}, Cint, Cfloat), ucc.handle, typ, val)
end

function getNormalizedValue(ucc::UVCCameraControl, typ)
    val = Cfloat[1]
    @uvccall(:OSXUVCUVCCameraControlGetNormalizedValue,
        Cint, (Ptr{Void}, Cint, Ptr{Cfloat}), ucc.handle, typ, pointer(val))
    val[1]
end

# low-level interface

function getControlInfo(ucc::UVCCameraControl, typ)
    info = UVCControlInfo(0,0,0)
    @uvccall(:OSXUVCUVCCameraControlGetControlInfo,
        Cint, (Ptr{Void}, Cint, Ptr{UVCControlInfo}),
        ucc.handle, typ, &info)
    info
end

function getRangeForControl(ucc::UVCCameraControl, control::UVCControlInfo)
    range = UVCRange(0,0)
    @uvccall(:OSXUVCUVCCameraControlGetRangeForControl,
        Cint, (Ptr{Void}, Ref{UVCControlInfo}, Ptr{UVCRange}),
        ucc.handle, control, &range)
    range
end

### utils ###

function Base.dump(ucc::UVCCameraControl)
    ccall((:OSXUVCUVCCameraControlDump, libOSXUVC),
        Void, (Ptr{Void},), ucc.handle)
end

end # module

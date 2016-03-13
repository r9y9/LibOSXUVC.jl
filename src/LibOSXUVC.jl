module LibOSXUVC

export
    UVCControlInfo,
    UVCRange,
    UVCCameraControl,
    UVCControlType,
    setInterfaceIndex,
    getInterfaceIndex,
    setProcessingUnitId,
    getProcessingUnitId,
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

    function UVCCameraControl()
        handle = ccall((:OSXUVCUVCCameraControlCreate, libOSXUVC),
            Ptr{Void}, ())
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
    name = ccall((:UVCGetControlTypeShortString, libOSXUVC),
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

function setInterfaceIndex(ucc::UVCCameraControl, idx)
    @uvccall(:OSXUVCUVCCameraControlSetInterfaceIndex, Cint,
        (Ptr{Void}, UInt16), ucc.handle, idx)
end

function getInterfaceIndex(ucc::UVCCameraControl)
    idx = UInt16[1]
    @uvccall(:OSXUVCUVCCameraControlGetInterfaceIndex, Cint,
        (Ptr{Void}, Ptr{UInt16}), ucc.handle, pointer(idx))
    idx[1]
end

function setProcessingUnitId(ucc::UVCCameraControl, id)
    @uvccall(:OSXUVCUVCCameraControlSetProcessingUnitId, Cint,
        (Ptr{Void}, UInt16), ucc.handle, id)
end

function getProcessingUnitId(ucc::UVCCameraControl)
    id = UInt16[1]
    @uvccall(:OSXUVCUVCCameraControlGetProcessingUnitId, Cint,
        (Ptr{Void}, Ptr{UInt16}), ucc.handle, pointer(id))
    id[1]
end

# convenient constructor
function UVCCameraControl(idx, id, locationId::AbstractString)
    ucc = UVCCameraControl()
    setInterfaceIndex(ucc, idx)
    setProcessingUnitId(ucc, id)
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

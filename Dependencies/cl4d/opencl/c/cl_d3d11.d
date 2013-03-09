/**
 *	cl4d - object-oriented wrapper for the OpenCL C API
 *	written in the D programming language
 *
 *	Copyright:
 *		(c) 2009-2011 Andreas Hollandt
 *
 *	License:
 *		see LICENSE.txt
 */

// $Revision: 11708 $ on $Date: 2010-06-13 23:36:24 -0700 (Sun, 13 Jun 2010) $

module opencl.c.cl_d3d11;

version(Windows):

import opencl.c.cl;
import std.c.windows.windows;
import std.c.windows.com;

extern(System):

/******************************************************************************
 * cl_khr_d3d11_sharing														  *
 ******************************************************************************/

enum
{
// Error Codes
	CL_INVALID_D3D11_DEVICE_KHR				= -1006,
	CL_INVALID_D3D11_RESOURCE_KHR			= -1007,
	CL_D3D11_RESOURCE_ALREADY_ACQUIRED_KHR	= -1008,
	CL_D3D11_RESOURCE_NOT_ACQUIRED_KHR		= -1009,

// cl_context_info
	CL_CONTEXT_D3D11_DEVICE_KHR				= 0x401D,
	CL_CONTEXT_D3D11_PREFER_SHARED_RESOURCES_KHR = 0x402D,

// cl_mem_info
	CL_MEM_D3D11_RESOURCE_KHR				= 0x401E,

// cl_image_info
	CL_IMAGE_D3D11_SUBRESOURCE_KHR			= 0x401F,

// cl_command_type
	CL_COMMAND_ACQUIRE_D3D11_OBJECTS_KHR	= 0x4020,
	CL_COMMAND_RELEASE_D3D11_OBJECTS_KHR	= 0x4021,
}

enum cl_d3d11_device_source_khr : cl_uint
{
	CL_D3D11_DEVICE_KHR						= 0x4019,
	CL_D3D11_DXGI_ADAPTER_KHR				= 0x401A,
}
mixin(bringToCurrentScope!cl_d3d11_device_source_khr);

enum cl_d3d11_device_set_khr : cl_uint
{
	CL_PREFERRED_DEVICES_FOR_D3D11_KHR		= 0x401B,
	CL_ALL_DEVICES_FOR_D3D11_KHR			= 0x401C,
}
mixin(bringToCurrentScope!cl_d3d11_device_set_khr);


extern (C)
{
	extern IID IID_ID3D11Resource;
    extern IID IID_ID3D11Buffer;
    extern IID IID_ID3D11Texture2D;
    extern IID IID_ID3D11Texture3D;
}

enum D3D11_USAGE { 
  D3D11_USAGE_DEFAULT    = 0,
  D3D11_USAGE_IMMUTABLE  = 1,
  D3D11_USAGE_DYNAMIC    = 2,
  D3D11_USAGE_STAGING    = 3
}

enum D3D11_RESOURCE_DIMENSION { 
  D3D11_RESOURCE_DIMENSION_UNKNOWN    = 0,
  D3D11_RESOURCE_DIMENSION_BUFFER     = 1,
  D3D11_RESOURCE_DIMENSION_TEXTURE1D  = 2,
  D3D11_RESOURCE_DIMENSION_TEXTURE2D  = 3,
  D3D11_RESOURCE_DIMENSION_TEXTURE3D  = 4
}

enum D3D11_COUNTER { 
  D3D11_COUNTER_DEVICE_DEPENDENT_0  = 0x40000000
}

enum D3D11_COUNTER_TYPE { 
  D3D11_COUNTER_TYPE_FLOAT32  = 0,
  D3D11_COUNTER_TYPE_UINT16   = ( D3D11_COUNTER_TYPE_FLOAT32 + 1 ),
  D3D11_COUNTER_TYPE_UINT32   = ( D3D11_COUNTER_TYPE_UINT16 + 1 ),
  D3D11_COUNTER_TYPE_UINT64   = ( D3D11_COUNTER_TYPE_UINT32 + 1 )
}

enum D3D11_FEATURE { 
  D3D11_FEATURE_THREADING                     = 0,
  D3D11_FEATURE_DOUBLES                       = ( D3D11_FEATURE_THREADING + 1 ),
  D3D11_FEATURE_FORMAT_SUPPORT                = ( D3D11_FEATURE_DOUBLES + 1 ),
  D3D11_FEATURE_FORMAT_SUPPORT2               = ( D3D11_FEATURE_FORMAT_SUPPORT + 1 ),
  D3D11_FEATURE_D3D10_X_HARDWARE_OPTIONS      = ( D3D11_FEATURE_FORMAT_SUPPORT2 + 1 ),
  D3D11_FEATURE_D3D11_OPTIONS                 = ( D3D11_FEATURE_D3D10_X_HARDWARE_OPTIONS + 1 ),
  D3D11_FEATURE_ARCHITECTURE_INFO             = ( D3D11_FEATURE_D3D11_OPTIONS + 1 ),
  D3D11_FEATURE_D3D9_OPTIONS                  = ( D3D11_FEATURE_ARCHITECTURE_INFO + 1 ),
  D3D11_FEATURE_SHADER_MIN_PRECISION_SUPPORT  = ( D3D11_FEATURE_D3D9_OPTIONS + 1 ),
  D3D11_FEATURE_D3D9_SHADOW_SUPPORT           = ( D3D11_FEATURE_SHADER_MIN_PRECISION_SUPPORT + 1 )
}

enum DXGI_FORMAT : ulong { 
  DXGI_FORMAT_UNKNOWN                     = 0,
  DXGI_FORMAT_R32G32B32A32_TYPELESS       = 1,
  DXGI_FORMAT_R32G32B32A32_FLOAT          = 2,
  DXGI_FORMAT_R32G32B32A32_UINT           = 3,
  DXGI_FORMAT_R32G32B32A32_SINT           = 4,
  DXGI_FORMAT_R32G32B32_TYPELESS          = 5,
  DXGI_FORMAT_R32G32B32_FLOAT             = 6,
  DXGI_FORMAT_R32G32B32_UINT              = 7,
  DXGI_FORMAT_R32G32B32_SINT              = 8,
  DXGI_FORMAT_R16G16B16A16_TYPELESS       = 9,
  DXGI_FORMAT_R16G16B16A16_FLOAT          = 10,
  DXGI_FORMAT_R16G16B16A16_UNORM          = 11,
  DXGI_FORMAT_R16G16B16A16_UINT           = 12,
  DXGI_FORMAT_R16G16B16A16_SNORM          = 13,
  DXGI_FORMAT_R16G16B16A16_SINT           = 14,
  DXGI_FORMAT_R32G32_TYPELESS             = 15,
  DXGI_FORMAT_R32G32_FLOAT                = 16,
  DXGI_FORMAT_R32G32_UINT                 = 17,
  DXGI_FORMAT_R32G32_SINT                 = 18,
  DXGI_FORMAT_R32G8X24_TYPELESS           = 19,
  DXGI_FORMAT_D32_FLOAT_S8X24_UINT        = 20,
  DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS    = 21,
  DXGI_FORMAT_X32_TYPELESS_G8X24_UINT     = 22,
  DXGI_FORMAT_R10G10B10A2_TYPELESS        = 23,
  DXGI_FORMAT_R10G10B10A2_UNORM           = 24,
  DXGI_FORMAT_R10G10B10A2_UINT            = 25,
  DXGI_FORMAT_R11G11B10_FLOAT             = 26,
  DXGI_FORMAT_R8G8B8A8_TYPELESS           = 27,
  DXGI_FORMAT_R8G8B8A8_UNORM              = 28,
  DXGI_FORMAT_R8G8B8A8_UNORM_SRGB         = 29,
  DXGI_FORMAT_R8G8B8A8_UINT               = 30,
  DXGI_FORMAT_R8G8B8A8_SNORM              = 31,
  DXGI_FORMAT_R8G8B8A8_SINT               = 32,
  DXGI_FORMAT_R16G16_TYPELESS             = 33,
  DXGI_FORMAT_R16G16_FLOAT                = 34,
  DXGI_FORMAT_R16G16_UNORM                = 35,
  DXGI_FORMAT_R16G16_UINT                 = 36,
  DXGI_FORMAT_R16G16_SNORM                = 37,
  DXGI_FORMAT_R16G16_SINT                 = 38,
  DXGI_FORMAT_R32_TYPELESS                = 39,
  DXGI_FORMAT_D32_FLOAT                   = 40,
  DXGI_FORMAT_R32_FLOAT                   = 41,
  DXGI_FORMAT_R32_UINT                    = 42,
  DXGI_FORMAT_R32_SINT                    = 43,
  DXGI_FORMAT_R24G8_TYPELESS              = 44,
  DXGI_FORMAT_D24_UNORM_S8_UINT           = 45,
  DXGI_FORMAT_R24_UNORM_X8_TYPELESS       = 46,
  DXGI_FORMAT_X24_TYPELESS_G8_UINT        = 47,
  DXGI_FORMAT_R8G8_TYPELESS               = 48,
  DXGI_FORMAT_R8G8_UNORM                  = 49,
  DXGI_FORMAT_R8G8_UINT                   = 50,
  DXGI_FORMAT_R8G8_SNORM                  = 51,
  DXGI_FORMAT_R8G8_SINT                   = 52,
  DXGI_FORMAT_R16_TYPELESS                = 53,
  DXGI_FORMAT_R16_FLOAT                   = 54,
  DXGI_FORMAT_D16_UNORM                   = 55,
  DXGI_FORMAT_R16_UNORM                   = 56,
  DXGI_FORMAT_R16_UINT                    = 57,
  DXGI_FORMAT_R16_SNORM                   = 58,
  DXGI_FORMAT_R16_SINT                    = 59,
  DXGI_FORMAT_R8_TYPELESS                 = 60,
  DXGI_FORMAT_R8_UNORM                    = 61,
  DXGI_FORMAT_R8_UINT                     = 62,
  DXGI_FORMAT_R8_SNORM                    = 63,
  DXGI_FORMAT_R8_SINT                     = 64,
  DXGI_FORMAT_A8_UNORM                    = 65,
  DXGI_FORMAT_R1_UNORM                    = 66,
  DXGI_FORMAT_R9G9B9E5_SHAREDEXP          = 67,
  DXGI_FORMAT_R8G8_B8G8_UNORM             = 68,
  DXGI_FORMAT_G8R8_G8B8_UNORM             = 69,
  DXGI_FORMAT_BC1_TYPELESS                = 70,
  DXGI_FORMAT_BC1_UNORM                   = 71,
  DXGI_FORMAT_BC1_UNORM_SRGB              = 72,
  DXGI_FORMAT_BC2_TYPELESS                = 73,
  DXGI_FORMAT_BC2_UNORM                   = 74,
  DXGI_FORMAT_BC2_UNORM_SRGB              = 75,
  DXGI_FORMAT_BC3_TYPELESS                = 76,
  DXGI_FORMAT_BC3_UNORM                   = 77,
  DXGI_FORMAT_BC3_UNORM_SRGB              = 78,
  DXGI_FORMAT_BC4_TYPELESS                = 79,
  DXGI_FORMAT_BC4_UNORM                   = 80,
  DXGI_FORMAT_BC4_SNORM                   = 81,
  DXGI_FORMAT_BC5_TYPELESS                = 82,
  DXGI_FORMAT_BC5_UNORM                   = 83,
  DXGI_FORMAT_BC5_SNORM                   = 84,
  DXGI_FORMAT_B5G6R5_UNORM                = 85,
  DXGI_FORMAT_B5G5R5A1_UNORM              = 86,
  DXGI_FORMAT_B8G8R8A8_UNORM              = 87,
  DXGI_FORMAT_B8G8R8X8_UNORM              = 88,
  DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM  = 89,
  DXGI_FORMAT_B8G8R8A8_TYPELESS           = 90,
  DXGI_FORMAT_B8G8R8A8_UNORM_SRGB         = 91,
  DXGI_FORMAT_B8G8R8X8_TYPELESS           = 92,
  DXGI_FORMAT_B8G8R8X8_UNORM_SRGB         = 93,
  DXGI_FORMAT_BC6H_TYPELESS               = 94,
  DXGI_FORMAT_BC6H_UF16                   = 95,
  DXGI_FORMAT_BC6H_SF16                   = 96,
  DXGI_FORMAT_BC7_TYPELESS                = 97,
  DXGI_FORMAT_BC7_UNORM                   = 98,
  DXGI_FORMAT_BC7_UNORM_SRGB              = 99,
  DXGI_FORMAT_AYUV                        = 100,
  DXGI_FORMAT_Y410                        = 101,
  DXGI_FORMAT_Y416                        = 102,
  DXGI_FORMAT_NV12                        = 103,
  DXGI_FORMAT_P010                        = 104,
  DXGI_FORMAT_P016                        = 105,
  DXGI_FORMAT_420_OPAQUE                  = 106,
  DXGI_FORMAT_YUY2                        = 107,
  DXGI_FORMAT_Y210                        = 108,
  DXGI_FORMAT_Y216                        = 109,
  DXGI_FORMAT_NV11                        = 110,
  DXGI_FORMAT_AI44                        = 111,
  DXGI_FORMAT_IA44                        = 112,
  DXGI_FORMAT_P8                          = 113,
  DXGI_FORMAT_A8P8                        = 114,
  DXGI_FORMAT_B4G4R4A4_UNORM              = 115,
  DXGI_FORMAT_FORCE_UINT                  = 0xffffffffL
}

struct D3D11_BUFFER_DESC {
  UINT        ByteWidth;
  D3D11_USAGE Usage;
  UINT        BindFlags;
  UINT        CPUAccessFlags;
  UINT        MiscFlags;
  UINT        StructureByteStride;
}

struct DXGI_SAMPLE_DESC {
  UINT Count;
  UINT Quality;
}

struct D3D11_COUNTER_DESC {
  D3D11_COUNTER Counter;
  UINT          MiscFlags;
}

struct D3D11_COUNTER_INFO {
  D3D11_COUNTER LastDeviceDependentCounter;
  UINT          NumSimultaneousCounters;
  ubyte         NumDetectableParallelUnits;
}

struct D3D11_TEXTURE2D_DESC {
  UINT             Width;
  UINT             Height;
  UINT             MipLevels;
  UINT             ArraySize;
  DXGI_FORMAT      Format;
  DXGI_SAMPLE_DESC SampleDesc;
  D3D11_USAGE      Usage;
  UINT             BindFlags;
  UINT             CPUAccessFlags;
  UINT             MiscFlags;
}

struct D3D11_TEXTURE3D_DESC {
  UINT        Width;
  UINT        Height;
  UINT        Depth;
  UINT        MipLevels;
  DXGI_FORMAT Format;
  D3D11_USAGE Usage;
  UINT        BindFlags;
  UINT        CPUAccessFlags;
  UINT        MiscFlags;
}

interface ID3D11Device : IUnknown
{
	HRESULT CheckCounter(
	  	       	const D3D11_COUNTER_DESC *pDesc,
	  out      	D3D11_COUNTER_TYPE *pType,
	  out     	UINT *pActiveCounters,
	  out      	LPSTR szName,
	  		    UINT *pNameLength,
	  out       LPSTR szUnits,
	            UINT *pUnitsLength,
	  out       LPSTR szDescription,
	    		UINT *pDescriptionLength
	);	

	void CheckCounterInfo(
	  out  D3D11_COUNTER_INFO *pCounterInfo
	);	

	HRESULT CheckFeatureSupport(
	     	D3D11_FEATURE Feature,
	  out  	void *pFeatureSupportData,
	     	UINT FeatureSupportDataSize
	);

	// Uncompleted list
}

interface ID3D11DeviceChild : IUnknown
{
	void GetDevice(ID3D11Device **ppDevice);	
}

interface ID3D11Resource : ID3D11DeviceChild
{
	UINT GetEvictionPriority();
	void GetType(out  D3D11_RESOURCE_DIMENSION *rType);
	void SetEvictionPriority(UINT EvictionPriority);
}

interface ID3D11Buffer : ID3D11Resource
{
	void GetDesc(out D3D11_BUFFER_DESC *pDesc);
}

interface ID3D11Texture2D : ID3D11Resource
{
	void GetDesc(out D3D11_TEXTURE2D_DESC  *pDesc);
}

interface ID3D11Texture3D : ID3D11Resource
{
	void GetDesc(out D3D11_TEXTURE3D_DESC  *pDesc);
}

/******************************************************************************/

alias extern(System) cl_errcode function(
	cl_platform_id				platform,
	cl_d3d11_device_source_khr	d3d_device_source,
	void*						d3d_object,
	cl_d3d11_device_set_khr		d3d_device_set,
	cl_uint						num_entries, 
	cl_device_id*				devices, 
	cl_uint*					num_devices) clGetDeviceIDsFromD3D11NV_fn;

alias extern(System) cl_mem function(
	cl_context		context,
	cl_mem_flags	flags,
	ID3D11Buffer*	resource,
	cl_errcode*		errcode_ret) clCreateFromD3D11BufferNV_fn;

alias extern(System) cl_mem function(
	cl_context			context,
	cl_mem_flags		flags,
	ID3D11Texture2D*	resource,
	uint				subresource,
	cl_errcode*			errcode_ret) clCreateFromD3D11Texture2DNV_fn;

alias extern(System) cl_mem function(
	cl_context			context,
	cl_mem_flags		flags,
	ID3D11Texture3D*	resource,
	uint				subresource,
	cl_errcode*			errcode_ret) clCreateFromD3D11Texture3DNV_fn;

alias extern(System) cl_errcode function(
	cl_command_queue	command_queue,
	cl_uint				num_objects,
	const(cl_mem)*		mem_objects,
	cl_uint				num_events_in_wait_list,
	const(cl_event)*	event_wait_list,
	cl_event*			event) clEnqueueAcquireD3D11ObjectsNV_fn;

alias extern(System) cl_errcode function(
	cl_command_queue	command_queue,
	cl_uint				num_objects,
	const cl_mem*		mem_objects,
	cl_uint				num_events_in_wait_list,
	const cl_event*		event_wait_list,
	cl_event*			event) clEnqueueReleaseD3D11ObjectsNV_fn;
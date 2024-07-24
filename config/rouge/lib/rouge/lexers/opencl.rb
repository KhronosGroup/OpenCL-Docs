# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'cpp.rb'

    class OpenCL < Cpp
      title "OpenCL"
      desc "The OpenCL standard for heterogeneous computing from the Khronos Group"

      tag 'opencl'

      opencl_api_types = %w(
        cl_double cl_double2 cl_double3 cl_double4 cl_double8 cl_double16
        cl_float cl_float2 cl_float3 cl_float4 cl_float8 cl_float16
        cl_short cl_short2 cl_short3 cl_short4 cl_short8 cl_short16
        cl_int cl_int2 cl_int3 cl_int4 cl_int8 cl_int16
        cl_long cl_long2 cl_long3 cl_long4 cl_long8 cl_long16 
        cl_char cl_char2 cl_char3 cl_char4 cl_char8 cl_char16 
        cl_uchar cl_uchar2 cl_uchar3 cl_uchar4 cl_uchar8 cl_uchar16
        cl_half cl_half2 cl_half3 cl_half4 cl_half8 cl_half16
        cl_ushort cl_ushort2 cl_ushort3 cl_ushort4 cl_ushort8 cl_ushort16
        cl_uint cl_uint2 cl_uint3 cl_uint4 cl_uint8 cl_uint16
        cl_ulong cl_ulong2 cl_ulong3 cl_ulong4 cl_ulong8 cl_ulong16
        __cl_float4
        cl_GLint
        cl_GLenum
        cl_GLuint
        cl_d3d11_device_source_khr
        cl_d3d11_device_set_khr
        cl_dx9_media_adapter_type_khr
        cl_dx9_media_adapter_set_khr
        cl_d3d10_device_source_khr
        cl_d3d10_device_set_khr
        cl_dx9_device_source_intel
        cl_dx9_device_set_intel
        cl_accelerator_intel
        cl_accelerator_type_intel
        cl_accelerator_info_intel
        cl_diagnostics_verbose_level
        cl_va_api_device_source_intel
        cl_va_api_device_set_intel
        cl_GLsync
        CLeglImageKHR
        CLeglDisplayKHR
        CLeglSyncKHR
        cl_egl_image_properties_khr
        cl_device_partition_property_ext
        cl_mem_migration_flags_ext
        cl_image_pitch_info_qcom
        cl_queue_priority_khr
        cl_queue_throttle_khr
        cl_import_properties_arm
        cl_svm_mem_flags_arm
        cl_kernel_exec_info_arm
        cl_device_svm_capabilities_arm
        cl_gl_context_info
        cl_gl_object_type
        cl_gl_texture_info
        cl_gl_platform_info
        cl_platform_id
        cl_device_id
        cl_context
        cl_command_queue
        cl_mem
        cl_program
        cl_kernel
        cl_event
        cl_sampler
        cl_semaphore_khr
        cl_bool
        cl_bitfield
        cl_properties
        cl_device_type
        cl_platform_info
        cl_device_info
        cl_device_fp_config
        cl_device_mem_cache_type
        cl_device_local_mem_type
        cl_device_exec_capabilities
        cl_device_svm_capabilities
        cl_command_queue_properties
        cl_device_partition_property
        cl_device_affinity_domain
        cl_context_properties
        cl_context_info
        cl_queue_properties
        cl_queue_properties_khr
        cl_command_queue_info
        cl_channel_order
        cl_channel_type
        cl_mem_flags
        cl_svm_mem_flags
        cl_mem_object_type
        cl_mem_info
        cl_mem_migration_flags
        cl_mem_properties
        cl_image_info
        cl_buffer_create_type
        cl_addressing_mode
        cl_filter_mode
        cl_sampler_info
        cl_map_flags
        cl_pipe_properties
        cl_pipe_info
        cl_program_info
        cl_program_build_info
        cl_program_binary_type
        cl_build_status
        cl_kernel_info
        cl_kernel_arg_info
        cl_kernel_arg_address_qualifier
        cl_kernel_arg_access_qualifier
        cl_kernel_arg_type_qualifier
        cl_kernel_work_group_info
        cl_kernel_sub_group_info
        cl_event_info
        cl_command_type
        cl_profiling_info
        cl_sampler_properties
        cl_kernel_exec_info
        cl_context_memory_initialize_khr
        cl_device_terminate_capability_khr
        cl_device_unified_shared_memory_capabilities_intel
        cl_mem_properties_intel
        cl_mem_alloc_flags_intel
        cl_mem_info_intel
        cl_unified_shared_memory_type_intel
        cl_mem_advice_intel
        cl_device_atomic_capabilities
        cl_khronos_vendor_id
        cl_version
        cl_version_khr
        cl_device_device_enqueue_capabilities
        cl_mipmap_filter_mode_img
        cl_mem_alloc_flags_img
        cl_layer_info
        cl_layer_api_version
        cl_icdl_info
        cl_icd_dispatch
        cl_device_scheduling_controls_capabilities_arm
        cl_device_controlled_termination_capabilities_arm
        cl_command_queue_capabilities_intel
        cl_device_feature_capabilities_intel
        cl_device_integer_dot_product_capabilities_khr
        cl_semaphore_properties_khr
        cl_semaphore_reimport_properties_khr
        cl_semaphore_info_khr
        cl_semaphore_type_khr
        cl_semaphore_payload_khr
        cl_external_semaphore_handle_type_khr
        cl_external_memory_handle_type_khr
        cl_device_command_buffer_capabilities_khr
        cl_command_buffer_khr
        cl_sync_point_khr
        cl_command_buffer_info_khr
        cl_command_buffer_state_khr
        cl_command_buffer_properties_khr
        cl_command_buffer_flags_khr
        cl_command_properties_khr
        cl_mutable_command_khr
        cl_mutable_dispatch_fields_khr
        cl_mutable_command_info_khr
        cl_command_buffer_structure_type_khr
        cl_device_fp_atomic_capabilities_ext
        cl_image_requirements_info_ext
        cl_platform_command_buffer_capabilities_khr
        cl_mutable_dispatch_asserts_khr
        cl_dx9_surface_info_khr
        cl_motion_estimation_desc_intel
        cl_mem_ext_host_ptr
        cl_mem_ion_host_ptr
        cl_mem_android_native_buffer_host_ptr
        cl_image_format
        cl_image_desc
        cl_buffer_region
        cl_name_version
        cl_name_version_khr
        cl_device_pci_bus_info_khr
        cl_queue_family_properties_intel
        CL_VERSION_MAJOR_MASK_KHR
        CL_VERSION_MINOR_MASK_KHR
        CL_VERSION_PATCH_MASK_KHR
        CL_VERSION_MAJOR_KHR
        CL_VERSION_MINOR_KHR
        CL_VERSION_PATCH_KHR
        CL_MAKE_VERSION_KHR
        cl_device_integer_dot_product_acceleration_properties_khr
        cl_mutable_dispatch_arg_khr
        cl_mutable_dispatch_exec_info_khr
        cl_mutable_dispatch_config_khr
        cl_mutable_base_config_khr
      )

      # Here are some interesting tokens
      # https://pygments.org/docs/tokens/ unused in C++ we can reuse
      # in OpenCL mode:
      # Comment::Preproc
      # Keyword.Pseudo
      # Keyword.Reserved
      # Literal::String::Regex
      # Literal::String::Symbol
      # Name::Attribute
      # Name.Builtin.Pseudo
      # Name.Function.Magic
      # Name.Other
      # Name.Variable.Magic
      # Operator.Word
      # Generic
      # Generic.Deleted
      # Generic.Emph
      # Generic.Error
      # Generic.Heading
      # Generic.Inserted
      # Generic.Output
      # Generic.Prompt
      # Generic.Strong
      # Generic.Subheading
      # Generic.Traceback


      # Insert some specific rules at the beginning of the statement
      # rule of the C++ lexer
      prepend :statements do
        rule %r/(?:#{opencl_api_types.join('|')})\b/,
             Keyword::Type
      end

    end
  end
end

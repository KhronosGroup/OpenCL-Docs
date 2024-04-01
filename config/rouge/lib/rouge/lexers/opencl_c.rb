# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'cpp.rb'

    class OpenCL_C < Cpp
      title "OpenCL C"
      desc "The OpenCL C standard for heterogeneous computing from the Khronos Group"

      tag 'opencl_c'

      opencl_c_data_types = %w(
        char char2 char3 char4 char8 char16
        double double2 double3 double4 double8 double16
        float float2 float3 float4 float8 float16
        half half2 half3 half4 half8 half16
        int int2 int3 int4 int8 int16
        long long2 long3 long4 long8 long16
        short short2 short3 short4 short8 short16
        uchar uchar2 uchar3 uchar4 uchar8 uchar16
        uint uint2 uint3 uint4 uint8 uint16
        ulong ulong2 ulong3 ulong4 ulong8 ulong16
        ushort ushort2 ushort3 ushort4 ushort8 ushort16
        image1d_t
        image2d_t
        image3d_t
        image1d_buffer_t
        image1d_array_t
        image2d_array_t
        image2d_depth_t
        image2d_array_depth_t
        image2d_msaa_t
        sampler_t
        queue_t
        ndrange_t
        clk_event_t
        reserve_id_t
        event_t
        cl_mem_fence_flags
      )

      # Generic types used in OpenCL pseudo code descriptions
      opencl_c_generic_types = %w(
        charn
        ucharn
        shortn
        ushortn
        intn
        uintn
        longn
        ulongn
        halfn
        floatn
        doublen
        gentype
        igentype
        ugentype
        sgentype
      )

      opencl_c_functions = %w(
        # list of functions used in the spec:
        as_double4
        as_float3
        as_float4
        as_int4
        as_short2
        as_short8
        as_uint
        async_work_group_copy_fence
        async_work_group_copy_2D2D
        async_work_group_copy_3D3D
        atomic_compare_exchange_strong
        atomic_compare_exchange_strong_explicit
        atomic_compare_exchange_weak
        atomic_compare_exchange_weak_explicit
        atomic_exchange
        atomic_exchange_explicit
        atomic_flag_clear
        atomic_flag_clear_explicit
        atomic_flag_test_and_set
        atomic_flag_test_and_set_explicit
        atomic_init
        atomic_load
        atomic_load_explicit
        atomic_store
        atomic_store_explicit
        atomic_work_item_fence
        convert_char4_sat
        convert_float4
        convert_float4_rtp
        convert_int4
        convert_int4_rte
        convert_int4_sat
        convert_int4_sat_rte
        convert_ushort4_sat
        enqueue_kernel
        get_default_queue
        get_global_id
        get_group_id
        get_local_id
        mem_fence
        ndrange_1D
        printf
        read_imagef
        read_imagei
        read_imageui
        read_mem_fence
        release_event
        shuffle
        shuffle2
        work_group_barrier
        work_group_scan_inclusive_add
        write_imagef
        write_imagei
        write_imageui
        write_mem_fence
      )

      opencl_c_variables = %w(
        memory_order_acq_rel
        memory_order_acquire
        memory_order_relaxed
        memory_order_release
        memory_order_seq_cst
        memory_scope_device
        memory_scope_sub_group
        memory_scope_system
        memory_scope_work_group
        memory_scope_work_item
      )

      opencl_c_keywords = %w(
        __kernel kernel
        __read_only read_only
        __read_write read_write
        __write_only write_only
        __global global
        __local local
        __constant constant
        __private private
        uniform
        pipe
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
        rule %r/(?:#{opencl_c_data_types.join('|')})\b/,
             Keyword::Type
        rule %r/(?:#{opencl_c_functions.join('|')})\b/,
            Name::Function::Magic
        rule %r/(?:#{opencl_c_generic_types.join('|')})\b/,
             Keyword::Pseudo
        rule %r/(?:#{opencl_c_variables.join('|')})\b/,
             Name::Variable::Magic
        rule %r/(?:#{opencl_c_keywords.join('|')})\b/,
             Name::Other
      end

    end
  end
end

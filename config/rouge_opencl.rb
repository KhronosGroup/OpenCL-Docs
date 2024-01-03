# -*- coding: utf-8 -*- #
# frozen_string_literal: true
# Copyright (c) 2011-2024 The Khronos Group, Inc.
# SPDX-License-Identifier: Apache-2.0

#puts "Loading rouge_opencl extensions for source code highlighting..."

require 'rouge'

RUBY_ENGINE == 'opal' ? (require 'rouge/lib/rouge/lexers/opencl' ;
                         require 'rouge/lib/rouge/lexers/opencl_c' ;
                         require 'rouge/lib/rouge/themes/opencl_spec') \
                      : (require_relative 'rouge/lib/rouge/lexers/opencl' ;
                         require_relative 'rouge/lib/rouge/lexers/opencl_c' ;
                         require_relative 'rouge/lib/rouge/themes/opencl_spec')

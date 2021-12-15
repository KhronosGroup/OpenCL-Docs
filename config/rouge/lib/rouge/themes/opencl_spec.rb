# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# The OpenCL theme used by Khronos in the OpenCL specification

module Rouge
  module Themes
    class OpenCLspec < Github
      name 'opencl.spec'

      # Use mostly :bold versions to be clearer and because :italic
      # does not work with asciidoctor-pdf

      # opencl_c_generic_types
      style Keyword::Pseudo,                  :fg => '#445588', :italic => true, :bold => true
      # opencl_c_functions
      style Name::Function::Magic,            :fg => '#00c5cd', :bold => true
      # opencl_c_opencl_keywords
      style Name::Other,                      :fg => '#ff4500', :bold => true
      # opencl_c_variables
      style Name::Variable::Magic,            :fg => '#ffa500', :bold => true
      # Make the gray comments a little more visible
      style Comment::Multiline,               :fg => '#555544', :italic => true
      style Comment::Preproc,                 :fg => '#555555', :bold => true
      style Comment::Single,                  :fg => '#555544', :italic => true
      style Comment::Special,                 :fg => '#555555', :italic => true, :bold => true
      style Comment,                          :fg => '#555544', :italic => true
    end
  end
end

require 'varnish'
require 'ffi'
require 'varnish/vsl/enum'

module Varnish
  module VSL
    extend FFI::Library
    ffi_lib Varnish::LIBVARNISHAPI
    include Enum

    callback :VSL_handler_f, [:pointer, VslTag, :int, :int, VslSpec, :pointer, :int64], :int

    attach_function 'VSL_Setup',    [ :pointer ], :void
    attach_function 'VSL_Open',     [ :pointer, :int ], :int
    attach_function 'VSL_Dispatch', [ :pointer, :VSL_handler_f, :pointer ], :int
  end
end

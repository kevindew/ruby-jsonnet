require 'mkmf'
require 'fileutils'

def using_system_libraries?
  arg_config('--use-system-libraries', !!ENV['JSONNET_USE_SYSTEM_LIBRARIES'])
end

dir_config('jsonnet')

unless using_system_libraries?
  message "Building jsonnet using packaged libraries.\n"
  require 'rubygems'
  gem 'mini_portile2', '~> 2.2.0'
  require 'mini_portile2'
  message "Using mini_portile version #{MiniPortile::VERSION}\n"

  recipe = MiniPortile.new('jsonnet', 'v0.9.4')
  recipe.files = ['https://github.com/google/jsonnet/archive/v0.9.4.tar.gz']
  class << recipe

    def compile
      execute('compile', make_cmd)
      execute('archive', 'ar rcs libjsonnet.a core/desugarer.o core/formatter.o core/lexer.o core/libjsonnet.o core/parser.o core/pass.o core/static_analysis.o core/string_utils.o core/vm.o third_party/md5/md5.o')
    end

    def configured?
      true
    end

    def install
      lib_path = File.join(port_path, 'lib')
      include_path = File.join(port_path, 'include')

      FileUtils.mkdir_p([lib_path, include_path])

      FileUtils.cp(File.join(work_path, 'libjsonnet.a'), lib_path)
      FileUtils.cp(File.join(work_path, 'include', 'libjsonnet.h'), include_path)
    end
  end

  recipe.cook
  # I tried using recipe.activate here but that caused this file to build ok
  # but the makefile to fail. These commands add the necessary paths to do both
  $LIBPATH = ["#{recipe.path}/lib"] | $LIBPATH
  $CPPFLAGS << " -I#{recipe.path}/include"
end

abort 'libjsonnet.h not found' unless have_header('libjsonnet.h')
abort 'libjsonnet not found' unless have_library('jsonnet')
create_makefile('jsonnet/jsonnet_wrap')

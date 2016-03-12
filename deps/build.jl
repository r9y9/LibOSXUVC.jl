using BinDeps
using Compat

@BinDeps.setup

const libOSXUVC_version = "master"

ignore_paths = split(strip(get(ENV, "LIBOSXUVCJL_LIBRARY_IGNORE_PATH", "")), ':')

validate = function(libpath, handle)
    for path in ignore_paths
        isempty(path) && continue
        ismatch(Regex("^$(path)"), libpath) && return false
    end
    return true
end

libOSXUVC = library_dependency("libOSXUVC", validate=validate)

# Yes, this is closed for now
github_root = "http://github.team-lab.local/ryuyamamoto/libOSXUVC"

provides(Sources,
         URI("$(github_root)/archive/$(libOSXUVC_version).tar.gz"),
         libOSXUVC,
         unpacked_dir="libOSXUVC-$(libOSXUVC_version)")

prefix = joinpath(BinDeps.depsdir(libOSXUVC), "usr")
srcdir = joinpath(BinDeps.depsdir(libOSXUVC), "src", "libOSXUVC-$(libOSXUVC_version)")

cmake_options = [
    "-DCMAKE_INSTALL_PREFIX=$prefix",
    "-DCMAKE_BUILD_TYPE=RELEASE",
]

provides(SimpleBuild,
          (@build_steps begin
              GetSources(libOSXUVC)
              @build_steps begin
                  ChangeDirectory(srcdir)
                  `mkdir -p build`
                  @build_steps begin
                      ChangeDirectory(joinpath(srcdir, "build"))
                      `rm -f CMakeCache.txt`
                      `cmake $cmake_options ..`
                      `make -j4`
                      `make install`
                  end
                end
          end), libOSXUVC, os = :Unix)

@BinDeps.install @compat Dict(:libOSXUVC => :libOSXUVC)

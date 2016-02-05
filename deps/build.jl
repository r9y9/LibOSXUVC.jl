using BinDeps
using Compat

@BinDeps.setup

const libosxuvc_version = "master"

ignore_paths = split(strip(get(ENV, "LIBOSXUVCJL_LIBRARY_IGNORE_PATH", "")), ':')

validate = function(libpath, handle)
    for path in ignore_paths
        isempty(path) && continue
        ismatch(Regex("^$(path)"), libpath) && return false
    end
    return true
end

libosxuvc = library_dependency("libosxuvc", validate=validate)

# Yes, this is closed for now
github_root = "http://github.team-lab.local/ryuyamamoto/libosxuvc"

provides(Sources,
         URI("$(github_root)/archive/$(libosxuvc_version).tar.gz"),
         libosxuvc,
         unpacked_dir="libosxuvc-$(libosxuvc_version)")

prefix = joinpath(BinDeps.depsdir(libosxuvc), "usr")
srcdir = joinpath(BinDeps.depsdir(libosxuvc), "src", "libosxuvc-$(libosxuvc_version)")

cmake_options = [
    "-DCMAKE_INSTALL_PREFIX=$prefix",
    "-DCMAKE_BUILD_TYPE=RELEASE",
]

provides(SimpleBuild,
          (@build_steps begin
              GetSources(libosxuvc)
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
          end), libosxuvc, os = :Unix)

@BinDeps.install @compat Dict(:libosxuvc => :libosxuvc)

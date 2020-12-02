""" Rules to run deepcopy-gen
"""

load("@io_bazel_rules_go//go:def.bzl", "go_context", "go_path")
load("@io_bazel_rules_go//go/private:providers.bzl", "GoPath")

def _deepcopy_gen_action(ctx, outputs):
    """ Run deepcopy-gen in the sandbox.

    This function sets up the necessary dependencies in the Bazel sandbox to
    run deepcopy-gen (which compiles Go code), then creates an action that
    runs it.

    Args:
      ctx         - The Rule's context
      output      - List of File/Dir produced by the action (delcare dependencies)
    """

    # TODO: what should GOPATH be if there are no dependencies?
    go_ctx = go_context(ctx)
    cg_info = ctx.toolchains["@rules_kubebuilder//deepcopy-gen:toolchain"].deepcopy_gen_info
    outputFileBase = ctx.attr.outputFileBase
    gopath = ""
    if ctx.attr.gopath_dep:
        gopath = "$(pwd)/" + ctx.bin_dir.path + "/" + ctx.attr.gopath_dep[GoPath].gopath
        # gopath = "export GOPATH=$(pwd)/" + ctx.bin_dir.path + "/" + ctx.attr.gopath_dep[GoPath].gopath + " &&"
    
    inputDirs = depset([s.dirname for s in ctx.files.srcs])
    
    cmd = """
          source <($PWD/{godir}/go env) &&
          export PATH=$GOROOT/bin:$PWD/{godir}:$PATH &&
          export GOPATH={gopath} &&
          mkdir -p .gocache &&
          export GOCACHE=$PWD/.gocache &&
          {cmd} {args}
        """.format(
        godir = go_ctx.go.path[:-1 - len(go_ctx.go.basename)],
        gopath = gopath,
        cmd = "$(pwd)/" + cg_info.deepcopy_gen_bin.path,
        args = "-O {outfilebase} -i {files}".format(
            outfilebase = ctx.attr.outputFileBase,
            files = ",".join(["$(pwd)/" + i + '/...' for i in inputDirs.to_list()]),
        ),
    )
    ctx.actions.run_shell(
        mnemonic = "DeepcopyGen",
        outputs = outputs,
        inputs = _inputs(ctx, go_ctx),
        env = _env(),
        command = cmd,
        tools = [
            go_ctx.go,
            cg_info.deepcopy_gen_bin,
        ],
    )

def _inputs(ctx, go_ctx):
    inputs = (ctx.files.srcs + go_ctx.sdk.srcs + go_ctx.sdk.tools +
              go_ctx.sdk.headers + go_ctx.stdlib.libs)

    if ctx.attr.gopath_dep:
        inputs += ctx.attr.gopath_dep.files.to_list()
    return inputs

def _env():
    return {
        "GO111MODULE": "off",  # explicitly relying on passed in go_path to not download modules while doing codegen
    }

def _deepcopy_gen_impl(ctx):
    outputFileName = ctx.attr.outputFileBase + ".go"
    output = ctx.actions.declare_file(outputFileName)

    _deepcopy_gen_action(ctx, [output])

    return DefaultInfo(
        files = depset([output]),
    )

COMMON_ATTRS = {
    "srcs": attr.label_list(
        allow_empty = False,
        allow_files = True,
        mandatory = True,
        doc = "Source files passed to deepcopy-gen",
    ),
    "gopath_dep": attr.label(
        providers = [GoPath],
        mandatory = False,
        doc = "Go lang dependencies, automatically bundled in a go_path() by the macro.",
    ),
    "_go_context_data": attr.label(
        default = "@io_bazel_rules_go//:go_context_data",
        doc = "Internal, context for go compilation.",
    ),
}

def _extra_attrs():
    ret = COMMON_ATTRS
    ret.update({
        "outputFileBase": attr.string(
            default = "zz_generated.deepcopy",
            doc = "Base name (without .go suffix) for output files. (default \"zz_deepcopy.generated\")"
        ),
        # "goHeaderFile": attr.string(
        # ),
    })
    return ret

def _toolchains():
    return [
        "@io_bazel_rules_go//go:toolchain",
        "@rules_kubebuilder//deepcopy-gen:toolchain",
    ]

_deepcopy_gen = rule(
    implementation = _deepcopy_gen_impl,
    attrs = _extra_attrs(),
    toolchains = _toolchains(),
    doc = "Run the code generation part of deepcopy-gen. " +
          "You can use the name of this rule as part of the `srcs` attribute " +
          " of a `go_library` rule.",
)

def _maybe_add_gopath_dep(name, kwargs):
    if kwargs.get("deps", None):
        gopath_name = name + "_deepcopy_gen"
        go_path(
            name = gopath_name,
            deps = kwargs["deps"],
        )
        kwargs["gopath_dep"] = gopath_name
        kwargs.pop("deps")

def deepcopy_gen(name, **kwargs):
    _maybe_add_gopath_dep(name, kwargs)
    _deepcopy_gen(name = name, **kwargs)

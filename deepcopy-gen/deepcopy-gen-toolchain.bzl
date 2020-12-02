""" Toolchain definitions for deepcopy-gen
"""

DeepCopyGenInfo = provider(
    doc = "Information about how to invoke deepcopy-gen",
    fields = ["deepcopy_gen_bin"],
)

def _deepcopy_gen_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        deepcopy_gen_info = DeepcopyGenInfo(
            deepcopy_gen_bin = ctx.file.deepcopy_gen_bin,
        ),
    )
    return [toolchain_info]

deepcopy_gen_toolchain = rule(
    implementation = _deepcopy_gen_toolchain_impl,
    attrs = {
        "deepcopy_gen_bin": attr.label(allow_single_file = True),
    },
)

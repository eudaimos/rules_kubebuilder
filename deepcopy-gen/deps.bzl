""" Dependencies for deepcopy-gen
"""

def deepcopy_gen_register_toolchain(name = None):
    native.register_toolchains(
        "@rules_kubebuilder//deepcopy-gen:deepcopy_gen_linux_toolchain",
        "@rules_kubebuilder//deepcopy-gen:deepcopy_gen_darwin_toolchain",
    )

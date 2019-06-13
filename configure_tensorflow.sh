#!/bin/bash

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dst_dir="${script_dir}/model/tensorflow"
tmp_dir="/tmp/happygo_tmp"
tmp_pkg_dir="/tmp/tensorflow_pkg"

rm -rfd ${tmp_dir}
rm -rfd ${tmp_pkg_dir}
mkdir -p ${tmp_dir}

rm -rf ${dst_dir}/*
mkdir -p ${dst_dir}

# TODO(tommadams): we should probably switch to Clang at some point.
commit_tag="v1.13.0-rc2"

echo "Cloning TensorFlow to ${tmp_dir}"
git clone https://github.com/tensorflow/tensorflow "${tmp_dir}"

pushd "${tmp_dir}"

echo "Checking out ${commit_tag}"
git checkout "${commit_tag}"

# Run the TensorFlow configuration script, setting reasonable values for most
# of the options.
echo "Configuring TensorFlow"
cc_opt_flags="${CC_OPT_FLAGS:--march=native}"

PYTHON_BIN_PATH=`which python`

CC_OPT_FLAGS="${cc_opt_flags}" \
TF_NEED_JEMALLOC=${TF_NEED_JEMALLOC:-1} \
TF_NEED_GCP=${TF_NEED_GCP:-1} \
TF_NEED_HDFS=${TF_NEED_HDFS:-0} \
TF_NEED_S3=${TF_NEED_S3:-0} \
TF_NEED_KAFKA=${TF_NEED_KAFKA:-0} \
TF_NEED_CUDA=${TF_NEED_CUDA:-1} \
TF_NEED_GDR=${TF_NEED_GDR:-0} \
TF_NEED_VERBS=${TF_NEED_VERBS:-0} \
TF_NEED_OPENCL_SYCL=${TF_NEED_OPENCL_SYCL:-0} \
TF_CUDA_CLANG=${TF_CUDA_CLANG:-0} \
TF_NEED_TENSORRT=${TF_NEED_TENSORRT:-0} \
TF_NEED_MPI=${TF_NEED_MPI:-0} \
TF_SET_ANDROID_WORKSPACE=${TF_SET_ANDROID_WORKSPACE:-0} \
TF_NCCL_VERSION=${TF_NCCL_VERSION:-2.4} \
./configure

echo "Building TensorFlow package"
bazel build -c opt --config=opt --copt="${cc_opt_flags}" //tensorflow/tools/pip_package:build_pip_package
bazel-bin/tensorflow/tools/pip_package/build_pip_package ${tmp_pkg_dir}

echo "TensorFlow built-ish"
echo "Unpacking TensorFlow package..."
unzip -q ${tmp_pkg_dir}/tensorflow-*.whl -d ${tmp_dir}

echo "Copying TensorFlow headers to ${dst_dir}"
cp -r ${tmp_dir}/tensorflow-*.data/purelib/tensorflow/include/* "${dst_dir}"

echo "Building TensorFlow libraries"

# Add a custom BUILD target for the gRPC runtime.
# TODO(tommadams): Remove this once the gRPC runtime is linked in to TensorFlow.
cat <<EOF >> tensorflow/BUILD

tf_cc_shared_object(
    name = "libgrpc_runtime.so",
    linkopts = select({
        "//tensorflow:darwin": [
            "-Wl,-exported_symbols_list",  # This line must be directly followed by the exported_symbols.lds file
            "\$(location //tensorflow:tf_exported_symbols.lds)",
        ],
        "//tensorflow:windows": [],
        "//conditions:default": [
            "-z defs",
            "-Wl,--version-script",  #  This line must be directly followed by the version_script.lds file
            "\$(location //tensorflow:tf_version_script.lds)",
        ],
    }),
    deps = [
        "//tensorflow:tf_exported_symbols.lds",
        "//tensorflow:tf_version_script.lds",
        "//tensorflow/core/distributed_runtime/rpc:grpc_runtime",
    ]
)
EOF

bazel build -c opt --config=opt --copt="${cc_opt_flags}" \
    //tensorflow:libgrpc_runtime.so \
    //tensorflow:libtensorflow_cc.so \
    //tensorflow:libtensorflow_framework.so

echo "Copying TensorFlow libraries to ${dst_dir}"
cp bazel-bin/tensorflow/{libgrpc_runtime,libtensorflow_*}.so "${dst_dir}"

popd
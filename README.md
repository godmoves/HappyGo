[![CircleCI](https://circleci.com/bb/mankitpong/happygo/tree/trt5.svg?style=svg&circle-token=66b3dbb293ddd4cf7a13af92eb7e9b1952215f06)](https://circleci.com/bb/mankitpong/happygo/tree/trt5)

**Status:** Active, breaking changes may occur.

**TODO:**  
  - [x] update to TensorRT 5  
  - [x] update to TensorFlow 1.12  
  - [ ] clean up code  
  - [ ] move structure TreeNode to a better file, it should belong to mcts
  - [ ] consider add sgf- and board- prefix to differ XToStr and StrToX
  - [ ] add tests and benchmarks  

# Leela Zero X PhoenixGo

## About PhoenixGo

![PhoenixGo](images/logo.jpg?raw=true)

**PhoenixGo** is an Go AI program which implement the AlphaGo Zero paper
"[Mastering the game of Go without human knowledge](https://deepmind.com/documents/119/agz_unformatted_nature.pdf)".
It is also known as "BensonDarr" in FoxGo, "cronus" in CGOS,
and the champion of "World AI Go Tournament 2018" held in Fuzhou China.

If you use PhoenixGo in your project, please consider mentioning in your README.

If you use PhoenixGo in your research, please consider citing the library as follows:

```
@misc{PhoenixGo2018,
  author = {Qinsong Zeng and Jianchang Zhang and Zhanpeng Zeng and Yongsheng Li and Ming Chen and Sifan Liu}
  title = {PhoenixGo},
  year = {2018},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/Tencent/PhoenixGo}}
}
```

## About Leela Zero

**Leela Zero** is a free and open-source computer Go software released on 25 October 2017.
It is developed by Belgian programmer [Gian-Carlo Pascutto](https://github.com/gcp), the author of chess engine Sjeng and Go engine Leela.

Leela Zero's algorithm is based on DeepMind's 2017 paper about AlphaGo Zero.
Unlike the original Leela, which has a lot of human knowledge and heuristics programmed into it, Leela Zero only knows the basic rules and nothing more.

Leela Zero is trained by a distributed effort, which is coordinated at the [Leela Zero website](http://zero.sjeng.org/). Members of the community provide computing resources by running the client, which generates self-play games and submits them to the server. The self-play games are used to train newer networks. Generally, over 500 clients have connected to the server to contribute resources. The community has provided high quality code contributions as well.

Leela Zero finished third at the BerryGenomics Cup World AI Go Tournament in Fuzhou, Fujian, China on 28 April 2018.

Additionally, in early 2018 the same team branched Leela Chess Zero from the same code base, also to verify the methods in the AlphaZero paper as applied to the game of chess. AlphaZero's use of Google TPUs was replaced by a crowd-sourcing infrastructure and the ability to use graphics card GPUs via the OpenCL library. Even so, it is expected to take a year of crowd-sourced training to make up for the dozen hours that AlphaZero was allowed to train for its chess match in the paper.

## Convert Leela Zero weight

### Dependencies

- Python 3.5 on Ubuntu 16.04 / Python 3.x on Ubuntu 18.04  
- Numpy  
- PyCUDA  
- TensorFlow 1.12+  
- [TensorRT 5](https://docs.nvidia.com/deeplearning/sdk/tensorrt-developer-guide/index.html#overview)  
- [UFF](https://docs.nvidia.com/deeplearning/sdk/tensorrt-api/python_api/index.html#installing-the-uff-toolkit)  
- CMake 3.1+  
- GCC 6/7  

Use `pip` to install what you need. For `tensorrt`, `pycuda` and `uff`, you can
find more info [here](https://docs.nvidia.com/deeplearning/sdk/tensorrt-developer-guide/index.html#overview).   
You need to install `tensorrt` by **tar package** to get python support. Find more info about how to [download and install](https://developer.nvidia.com/tensorrt). 

### Build uff_to_plan and convert weight

First `git clone` this repository, then execute the commands below:
```
$ cd scripts/uff2plan
$ mkdir build && cd build
$ cmake ..
$ make
$ cd ../..
$ python net_to_model.py </path/to/lz-weight>
```
You will get the `.uff`, `.PLAN` and the Tensorflow format of Leela Zero weight. Copy them to `ckpt` folder.

### Modify the configure file

You will need to modify the configure files in `etc` to use the converted LZ weight. 

For example, if you want to use the TensorRT version, you need to change `tensorrt_model_path` in
`mcts_*gpu.conf` like `tensorrt_model_path: "leelaz-model-0.PLAN"`. Or if you want to use the no TensorRT
version, then add `meta_graph_path: "leelaz-model-0.meta"` into `model_config` and change the content of 
`ckpt/checkpoint` into `model_checkpoint_path: "leelaz-model-0"`.

### Run in ELF mode

By enable `value_form_black` option in configure file:
```
model_config {
    train_dir: "ckpt.elf"
    enable_tensorrt: 1
    tensorrt_model_path: "leelaz-elf-0.PLAN"
    value_from_black: 1
}
```

### MyLizzie support (experimental)

You can run the program in [myLizzie](https://github.com/aerisnju/mylizzie) mode by add flag `--lizzie` in command line.  
For example:
```
$ bazel-bin/mcts/mcts_main --config_path=etc/mcts_1gpu.conf --gtp --logtostderr --v=1 --lizzie
```

**Known issue:** speed loss when there are too many points, turn off the pv may help with this. 

## Build the engine on Linux

### Requirements

* GCC with C++11 support
* Bazel (0.19.2 is known-good, 0.20.2 has some [issues](https://github.com/tensorflow/tensorflow/issues/24124))
* CUDA 10 and cuDNN 7 (for GPU support)
* TensorRT (for accelerating computation on GPU, 5.0.2 is known-good)

### Building

Clone the repository and configure the building:

```
$ git clone https://github.com/godmoves/HappyGo.git
$ cd HappyGo
$ ./configure
```

`./configure` will ask where CUDA and TensorRT have been installed, specify them if need.

Then build with bazel, a known issue of bazel 0.19.2 is mentioned [here](https://github.com/tensorflow/tensorflow/issues/23401#issuecomment-434681778):

```
$ bazel build //mcts:mcts_main
```

Dependices such as Tensorflow will be downloaded automatically. The building prosess may take a long time.

### Running

Download and extract the trained network, then run:

Convert the Leela Zero weight as mentioned before, and run
```
$ scripts/start.sh
```
or
```
$ bazel-bin/mcts/mcts_main --config_path=etc/{config} --gtp --logtostderr --v=1
```

`start.sh` will detect the number of GPUs, run `mcts_main` with proper config file, and write log files in directory `log`.
You could also use a customized config by running `scripts/start.sh {config_path}`.
See also [configure-guide](#configure-guide).

Furthermore, if you want to fully control all the options of `mcts_main` (such as, changing log destination),
you could also run `bazel-bin/mcts/mcts_main` directly. See also [command-line-options](#command-line-options).

The engine supports the GTP protocol, means it could be used with a GUI with GTP capability,
such as [Sabaki](http://sabaki.yichuanshen.de).

`--logtostderr` let `mcts_main` log messages to stderr, if you want to log to files,
change `--logtostderr` to `--log_dir={log_dir}`	

You could modify your config file following [configure-guide](#configure-guide).

### Distribute mode

PhoenixGo support running with distributed workers, if there are GPUs on different machine.

Build the distribute worker:

```
$ bazel build //dist:dist_zero_model_server
```

Run `dist_zero_model_server` on distributed worker, **one for each GPU**.

```
$ CUDA_VISIBLE_DEVICES={gpu} bazel-bin/dist/dist_zero_model_server --server_address="0.0.0.0:{port}" --logtostderr
```

Fill `ip:port` of workers in the config file (`etc/mcts_dist.conf` is an example config for 32 workers),
and run the distributed master:

```
$ scripts/start.sh etc/mcts_dist.conf
```
or
```
$ bazel-bin/mcts/mcts_main --config_path=etc/mcts_dist.conf --gtp --logtostderr --v=1
```

## Configure Guide

Here are some important options in the config file:

* `num_eval_threads`: should equal to the number of GPUs
* `num_search_threads`: should a bit larger than `num_eval_threads * eval_batch_size`
* `timeout_ms_per_step`: how many time will used for each move
* `max_simulations_per_step`: how many simulations will do for each move
* `gpu_list`: use which GPUs, separated by comma
* `model_config -> train_dir`: directory where trained network stored
* `model_config -> checkpoint_path`: use which checkpoint, get from `train_dir/checkpoint` if not set
* `model_config -> enable_tensorrt`: use TensorRT or not
* `model_config -> tensorrt_model_path`: use which TensorRT model, if `enable_tensorrt`
* `max_search_tree_size`: the maximum number of tree nodes, change it depends on memory size
* `max_children_per_node`: the maximum children of each node, change it depends on memory size
* `enable_background_search`: pondering in opponent's time
* `early_stop`: genmove may return before `timeout_ms_per_step`, if the result would not change any more
* `unstable_overtime`: think `timeout_ms_per_step * time_factor` more if the result still unstable
* `behind_overtime`: think `timeout_ms_per_step * time_factor` more if winrate less than `act_threshold`

Options for distribute mode:

* `enable_dist`: enable distribute mode
* `dist_svr_addrs`: `ip:port` of distributed workers, multiple lines, one `ip:port` in each line
* `dist_config -> timeout_ms`: RPC timeout

Options for async distribute mode:

> Async mode is used when there are huge number of distributed workers (more than 200),
> which need too many eval threads and search threads in sync mode.
> `etc/mcts_async_dist.conf` is an example config for 256 workers.

* `enable_async`: enable async mode
* `enable_dist`: enable distribute mode
* `dist_svr_addrs`: multiple lines, comma separated lists of `ip:port` for each line
* `num_eval_threads`: should equal to number of `dist_svr_addrs` lines
* `eval_task_queue_size`: tunning depend on number of distribute workers
* `num_search_threads`: tunning depend on number of distribute workers


Read `mcts/mcts_config.proto` for more config options.

## Command Line Options

`mcts_main` accept options from command line:

* `--config_path`: path of config file
* `--gtp`: run as a GTP engine, if disable, gen next move only
* `--init_moves`: initial moves on the go board
* `--gpu_list`: override `gpu_list` in config file
* `--listen_port`: work with `--gtp`, run gtp engine on port in TCP protocol
* `--allow_ip`: work with `--listen_port`, list of client ip allowed to connect
* `--fork_per_request`: work with `--listen_port`, fork for each request or not

Glog options are also supported:

* `--logtostderr`: log message to stderr
* `--log_dir`: log to files in this directory
* `--minloglevel`: log level, 0 - INFO, 1 - WARNING, 2 - ERROR
* `--v`: verbose log, `--v=1` for turning on some debug log, `--v=0` to turning off

`mcts_main --help` for more command line options.

## FAQ

**1. Where is the win rate?**

Print in the log, something like:

```
I0514 12:51:32.724236 14467 mcts_engine.cc:157] 1th move(b): dp, winrate=44.110905%, N=654, Q=-0.117782, p=0.079232, v=-0.116534, cost 39042.679688ms, sims=7132, height=11, avg_height=5.782244, global_step=639200
```

**2. There are too much log.**

Passing `--v=0` to `mcts_main` will turn off many debug log.
Moreover, `--minloglevel=1` and `--minloglevel=2` could disable INFO log and WARNING log.

Or, if you just don't want to log to stderr, replace `--logtostderr` to `--log_dir={log_dir}`,
then you could read your log from `{log_dir}/mcts_main.INFO`.

**3. How make PhoenixGo think with constant time per move?**

Modify your config file. `early_stop`, `unstable_overtime`, `behind_overtime` and
`time_control` are options that affect the search time, remove them if exist then
each move will cost constant time/simulations.

**4. GTP command `time_settings` doesn't work.**

Add these lines in your config:

```
time_control {
    enable: 1
    c_denom: 20
    c_maxply: 40
    reserved_time: 1.0
}
```

`c_denom` and `c_maxply` are parameters for deciding how to use the "main time".
`reserved_time` is how many seconds should reserved (for network latency) in "byo-yomi time".

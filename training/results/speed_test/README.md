## Speed test of different backends

All results are based on the speed of 1x1080ti on Ubuntu. Only the time of neural
network computation is included and the unit of results is positions/second.  

### Meaning of abbreviations

- lc0: [Leela Chess Zero](https://github.com/LeelaChessZero/lc0)  
- lz master: [master branch of Leela Zero](https://github.com/gcp/leela-zero/commit/9e903eda6e93fb65375ea03127e4f62268913175)
- lz fp16: [next branch of lz](https://github.com/gcp/leela-zero/commit/488de437e9c669da9870aefa39749322661bb8bf)
- Ttl batch: [OpenCL batching branch of Ttl fork](https://github.com/Ttl/leela-zero/tree/batching_test)  
- Ttl cudnn: [cuDNN branch of Ttl fork](https://github.com/Ttl/leela-zero/tree/cudnn)  
- ph go: [PhoenixGo](https://github.com/Tencent/PhoenixGo)

### Results

|Backend           |Batch size|Speed (15x192)|Speed (20x224)|
|------------------|----------|--------------|--------------|
|OpenCL (lz master)|1         |695           |457           |
|OpenCL (lz fp16)  |1         |718           |497           |
|OpenCL (Ttl batch)|1         |741           |452           |
|                  |2         |830           |480           |
|                  |4         |857           |530           |
|                  |8         |925           |582           |
|                  |16        |926           |603           |
|Cudnn (lc0)       |          |              |              |
|Cudnn (Ttl cudnn) |1         |520           |347           |
|TensorFlow (lc0)  |1         |138           |124           |
|                  |2         |273           |229           |
|                  |4         |537           |395           |
|                  |8         |826           |530           |
|                  |16        |1169          |729           |
|TensorFlow (ph go)|          |              |              | 
|TensorRT (ph go)  |1         |630           |410           |
|                  |2         |832           |519           |
|                  |4         |910           |580           |
|                  |8         |1004          |587           |
|                  |16        |1049          |599           |

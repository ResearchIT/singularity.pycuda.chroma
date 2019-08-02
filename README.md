# singularity.pycuda.chroma
Build a CentOS7.6 singularity container for archving legacy pycuda application chroma
(https://chroma.bitbucket.io/).

### 1. Build the container
The script build_chroma_simg.sh will build a base singularity sandbox of CentOS7.6 with  cuda9.1 and x11, install the required python2.7 packages, and create a  singularity image from the sandbox.

$ sudo sh ./build_chroma_simg.sh

### 2. Test
  We will run the simulation from a gpu node in a cluster.
chroma will use ~/.chroma as a cache location, and has six models included for testing, which are Colbert_HighRes_Brow, companioncube, liberty, MiniFig, tie_interceptor6, and lionsolid.

\# allocate a gpu node in the remote cluster
<br />$ ssh -X remote.cluster
<br />$ salloc -N1 -n4 -t1:0:0 -pgpu --gres=gpu:1

\# display the model lionsolid at the local computer. CUDA 9.1 is installed in chroma.simg.
<br />$ module load singularity
<br />$ module load cuda9.1
<br />$ nvidia-cuda-mps-server
<br />$ singularity exec --nv chroma.simg chroma-cam @chroma.models.lionsolid

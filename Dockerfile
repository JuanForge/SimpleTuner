# Do not modify this file or change its structure as long as it is maintained by JuanForge, who is responsible for the Dockerfile.

FROM docker.io/nvidia/cuda:13.3.0-cudnn-runtime-ubuntu24.04
#FROM docker.io/nvidia/cuda:13.3.0-cudnn-devel-ubuntu24.04 # cudnn-devel for headers files and build tools

# Using 'release' branch for stability. Change to 'main' for latest features.
ARG PYTHON_VERSION=3.12
ARG SIMPLETUNER_BRANCH=release


#ENV CUDA_HOME=/usr/local/cuda                                                                     - Unnecessary, as it is handled by the libraries.
#ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/targets/x86_64-linux/lib/stubs:$LD_LIBRARY_PATH   - Unnecessary, as it is handled by the libraries.

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    git-lfs \
    wget \
    curl \
    vim \
    tmux \
    htop \
    rsync \
    net-tools \
    openssh-server \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
    ffmpeg \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

# useless except for debugging : vim, htop

RUN git clone --depth 1 --single-branch --branch $SIMPLETUNER_BRANCH https://github.com/bghira/SimpleTuner.git .

COPY --chmod=755 docker-start.sh /app/start.sh

RUN python${PYTHON_VERSION} -m venv .venv

RUN .venv/bin/python -m pip install --upgrade pip setuptools wheel
RUN .venv/bin/python -m pip install --no-cache-dir "huggingface_hub[cli,hf_transfer]" wandb mpi4py ninja "torchao>=0.17.0,<0.18.0" psutil sageattention==1.0.6

# -- optional module --
RUN .venv/bin/python -m pip install --no-cache-dir ramtorch
# ----

RUN .venv/bin/python -m pip install --no-cache-dir -e .[jxl]

RUN chmod +x /app/docker-start.sh

ENTRYPOINT [ "/app/start.sh" ]
# CMD [".venv/bin/simpletuner", "server", "--host", "0.0.0.0", "--port", "8001"] # for bypass the sh file
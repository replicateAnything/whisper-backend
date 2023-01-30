FROM python:3.10

ENV POETRY_VERSION=1.2.0
ENV POETRY_VENV=/app/.venv

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get -qq install --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv $POETRY_VENV \
    && $POETRY_VENV/bin/pip3 install -U pip setuptools \
    && $POETRY_VENV/bin/pip3 install poetry==${POETRY_VERSION}

ARG TARGETPLATFORM
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then $POETRY_VENV/bin/pip3 install torch==1.13.0 -f https://download.pytorch.org/whl/cpu; fi;
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then $POETRY_VENV/bin/pip3 install torch==1.13.0; fi;

ENV PATH="${PATH}:${POETRY_VENV}/bin"

WORKDIR /app

COPY . /app

RUN poetry config virtualenvs.in-project true
RUN poetry install

ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:9000", "--workers", "4", "--timeout", "30", "app.webservice:app", "-k", "uvicorn.workers.UvicornWorker"]
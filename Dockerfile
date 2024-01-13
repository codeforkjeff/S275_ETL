
FROM python:3.9-slim-bullseye

WORKDIR /opt/s275

# System build dependencies
RUN \
  --mount=type=cache,mode=0755,target=/var/cache/apt,id=apt-cache,sharing=locked \
  --mount=type=cache,mode=0755,target=/var/lib/apt,id=apt-lib,sharing=locked \
  apt-get update \
  && apt-get --no-install-recommends -qq -y install \
    g++ \
    gcc \
    git \
    mdbtools \
    postgresql-client \
    zlib1g-dev

COPY requirements-postgres.txt ./

RUN \
  --mount=type=cache,mode=0755,target=/var/cache/pip,id=pip-cache \
  python3 -m venv /opt/venv \
  && /opt/venv/bin/python3 -m pip --cache-dir=/var/cache/pip install --upgrade pip wheel \
  && /opt/venv/bin/python3 -m pip --cache-dir=/var/cache/pip install -r requirements-postgres.txt \
  && rm requirements-postgres.txt

EXPOSE 8080

CMD ./elt.sh

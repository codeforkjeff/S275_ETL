
FROM python:3.12-slim-bullseye

ARG DATABASE=postgres
ENV DATABASE=${DATABASE:-postgres}

# System build dependencies
RUN \
  --mount=type=cache,mode=0755,target=/var/cache/apt,id=apt-cache,sharing=locked \
  --mount=type=cache,mode=0755,target=/var/lib/apt,id=apt-lib,sharing=locked \
  apt-get update \
  && apt-get --no-install-recommends -qq -y install \
    g++ \
    gcc \
    git \
    libpq-dev \
    mdbtools \
    postgresql-client \
    zlib1g-dev

COPY requirements-$DATABASE.txt ./requirements.txt

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

#RUN \
#  --mount=type=cache,mode=0755,target=/var/cache/pip,id=pip-cache \
#  python3 -m venv /opt/venv \
#  && /opt/venv/bin/python3 -m pip --cache-dir=/var/cache/pip install --upgrade pip wheel \
#  && /opt/venv/bin/python3 -m pip --cache-dir=/var/cache/pip install -r requirements.txt \
#  && rm requirements-postgres.txt

RUN uv venv

ENV PATH="$HOME/.venv/bin:$PATH"

RUN \
  --mount=type=cache,mode=0755,target=/var/cache/uv,id=uv-cache \
  uv --cache-dir /var/cache/uv pip install -r requirements.txt

RUN mkdir ~/.dbt
RUN cat > ~/.dbt/profiles.yml <<EOF
S275:

  outputs:

    postgres:
      type: postgres
      host: postgresql
      database: s275
      user: s275
      password: s275
      schema: public
      port: 5432
      threads: 1

    sqlite:
      type: sqlite
      threads: 1
      # database MUST exist in order for macros to work. its value is arbitrary.
      database: "database"
      schema: 'main'
      schemas_and_paths:
        main: '/opt/s275/output/S275.sqlite'
      schema_directory: '/opt/s275/output'

  target: $DATABASE

EOF

ENV PYTHONUNBUFFERED=1

WORKDIR /opt/s275

EXPOSE 8080

CMD ./elt.sh

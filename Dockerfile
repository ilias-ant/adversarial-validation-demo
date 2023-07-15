# this stage provides the base image & configuration
FROM python:3.10.12-bookworm AS python-base

LABEL org.opencontainers.image.version="0.1.0"
LABEL org.opencontainers.image.authors="Ilias Antonopoulos"
LABEL org.opencontainers.image.description="builds image for adversarial validation demo"

ENV PYTHONUNBUFFERED=1 \
    # prevents python creating .pyc files
    PYTHONDONTWRITEBYTECODE=1 \
    \
    # pip
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    \
    # https://python-poetry.org/docs/configuration/#using-environment-variables
    POETRY_VERSION=1.5.1 \
    # make poetry install to this location
    POETRY_HOME="/opt/poetry" \
    # make poetry create the virtual environment in the project's root directory
    # it gets named `.venv`
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # do not ask any interactive question
    POETRY_NO_INTERACTION=1 \
    \
    # this is where our virtual environment + dependencies will "live"
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv" \
    # this is where our application code will "live"
    APP_PATH="/app"

# prepend poetry and venv to path
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# this stage is used to  create our virtual environment + install required dependencies
FROM python-base AS builder-base

# install poetry - respects $POETRY_VERSION & $POETRY_HOME
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -sSL https://install.python-poetry.org | python3 -

# copy project dependency files here to ensure they will be cached
WORKDIR $PYSETUP_PATH
COPY pyproject.toml ./

# install runtime dependencies - uses $POETRY_VIRTUALENVS_IN_PROJECT internally
RUN poetry install --without dev

# this stage provides the `development` image
FROM python-base AS development

ENV ADVAL_ENV=development

COPY --from=builder-base $POETRY_HOME $POETRY_HOME
COPY --from=builder-base $PYSETUP_PATH $PYSETUP_PATH

WORKDIR $PYSETUP_PATH

RUN poetry install --with dev

WORKDIR $APP_PATH

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8888

ENTRYPOINT ["/docker-entrypoint.sh"]

# this stage provides the `production` image
FROM python-base AS production

ENV ADVAL_ENV=production

COPY --from=builder-base $POETRY_HOME $POETRY_HOME
COPY --from=builder-base $PYSETUP_PATH $PYSETUP_PATH

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8888

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root"]
# adversarial-validation-demo

### Reproduction

First build the image:
```shell
docker build \
    --target production \
    -t adval:latest \
    .
```

and then run the container:
```shell
docker run \
    --init \
    -p 8888:8888 \
    --mount type=bind,source=.,target=/app \
    adval:latest
```

Jupyter notebooks will be available for review & reproduction at: http://127.0.0.1:8888/tree (*requires token*)        
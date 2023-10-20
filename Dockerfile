FROM alpine:latest

RUN apk --no-cache add \
  bats \
  git \
  util-linux

WORKDIR /git-experimental-caravan

COPY . /git-experimental-caravan

CMD [ "./test/git-experimental-caravan.bats" ]

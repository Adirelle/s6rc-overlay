FROM -IMAGE-

RUN mkdir /tests
ADD user /tests/user
ADD root /tests/root
ADD services.d/root-tests /etc/services.d/root-tests
ADD check-env run-tests /bin/

RUN if test -e /etc/alpine-release; then \
        adduser -h /home/docker -s /bin/bash -D -g '' docker ; \
    else \
        adduser --home /home/docker -shell /bin/bash --disabled-password --gecos '' docker ; \
    fi

USER docker
WORKDIR /tmp

ENV S6_VERBOSITY=3 \
    BAR=FOO

CMD ["/bin/run-tests", "/tests/user"]

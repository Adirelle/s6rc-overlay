
ADD root-tests /root-tests
ADD user-tests /user-tests
ADD services.d/root-tests /etc/services.d/root-tests

RUN adduser --home /home/docker --shell /bin/bash --disabled-password -gecos '' docker

USER docker
WORKDIR /tmp

ENV S6_VERBOSITY=3 \
    REMOVE_PATHS=/root-tests/80-should-be-removed \
    WRITABLE_PATHS=/etc/shells \
    WRITABLE_USER=docker \
    BAR=FOO

CMD run-parts --exit-on-error /user-tests

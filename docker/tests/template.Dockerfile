
ADD root-tests /root-tests
ADD user-tests /user-tests
ADD services.d/root-tests /etc/services.d/root-tests

RUN adduser --home /home/docker --shell /bin/bash --disabled-password -gecos '' docker

RUN touch /usr/writable-file \
&&  chmod 0555 /usr/writable-file

USER docker
WORKDIR /tmp

ENV S6_VERBOSITY=3 \
    REMOVE_PATHS=/user-tests/80-should-be-removed \
    WRITABLE_PATHS=/usr/writable-file:/usr/writable-dir \
    WRITABLE_USER=docker \
    BAR=FOO

CMD run-parts --exit-on-error /user-tests

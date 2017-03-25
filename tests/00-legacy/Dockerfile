FROM -IMAGE-

RUN mkdir /tests
ADD user /tests/user
ADD root /tests/root
ADD services.d/root-tests /etc/services.d/root-tests
ADD check-env run-tests /bin/

RUN adduser --home /home/docker --shell /bin/bash --disabled-password -gecos '' docker

RUN touch /usr/writable-file \
&&  chmod 0555 /usr/writable-file

USER docker
WORKDIR /tmp

ENV S6_VERBOSITY=3 \
    REMOVE_PATHS=/tests/user/80-should-be-removed \
    WRITABLE_PATHS=/usr/writable-file:/usr/writable-dir \
    WRITABLE_USER=docker \
    BAR=FOO

CMD ["/bin/run-tests", "/tests/user"]

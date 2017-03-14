
ADD root-tests /root-tests
ADD user-tests /user-tests
ADD services.d/root-tests /etc/services.d/root-tests

RUN echo 2 >/etc/s6-rc/env/S6_VERBOSITY

USER daemon
WORKDIR /tmp
CMD run-parts --exit-on-error /user-tests
ENV REMOVE_PATHS=/root-tests/removePaths WRITABLE_PATHS=/run/bla WRITABLE_USER=daemon BAR=FOO

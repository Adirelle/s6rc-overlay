FROM -IMAGE-

ENV WRITABLE_USER="daemon" \
    WRITABLE_PATHS=/opt/writable:/etc/shells:foo

ADD test /opt/test

USER daemon

CMD ["/opt/test"]

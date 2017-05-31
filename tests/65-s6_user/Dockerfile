FROM -IMAGE-
RUN if test -e /etc/alpine-release; then \
        adduser -h /home/foo -s /bin/bash -D -g '' foo ; \
    else \
        adduser --home /home/foo -shell /bin/bash --disabled-password --gecos '' foo ; \
    fi

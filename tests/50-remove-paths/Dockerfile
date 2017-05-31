FROM -IMAGE-

RUN mkdir -p /opt/to-remove-dir \
&&  touch /opt/to-remove-file /opt/exact-remove /opt/to-remove-dir/recursive

ENV REMOVE_PATHS=/opt/to-remove-*:/opt/exact-remove

CMD s6-test ! -e /opt/to-remove-dir -a ! -e /opt/to-remove-file -a ! -e /opt/exact-remove -a -z "$REMOVE_PATHS"

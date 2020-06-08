from ruby:2.5
WORKDIR /

COPY cerberus.rb .
RUN chmod +x cerberus.rb


ENTRYPOINT ["/bin/bash"]
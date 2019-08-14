FROM radersolutions/haproxy:latest

ADD ./files/haproxy.cfg /etc/haproxy/haproxy.cfg

ADD ./files/scripts/* /usr/local/bin/

RUN chmod a+x /usr/local/bin/* 

CMD ["/usr/local/bin/start.sh"]

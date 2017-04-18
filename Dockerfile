FROM nginx:alpine

RUN apk add --no-cache inotify-tools
RUN mkdir -p /usr/share/nginx/html/images && \
    mkdir -p /usr/share/nginx/html/mock_cdn
ADD root/ /

CMD ["/runall.sh"]

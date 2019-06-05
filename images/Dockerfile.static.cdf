FROM nginx
EXPOSE 80
COPY *.svg /usr/share/nginx/html/
COPY index_cdf.html /usr/share/nginx/html/index.html

FROM nginx
EXPOSE 80
COPY index_cdf.html /usr/share/nginx/html/index.html

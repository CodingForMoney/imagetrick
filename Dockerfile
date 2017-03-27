# Dockerfile - imagetrick
# https://github.com/CodingForMoney/imagetrick

FROM openresty/openresty:centos
MAINTAINER luoxianming <luoxianmingg@gmail.com>
# 安装依赖包
RUN yum install -y gcc gcc-c++ zlib zlib-devel openssl openssl-devel pcre pcre-devel libpng libjpeg libpng-devel libjpeg-devel ghostscript libtiff libtiff-devel freetype freetype-devel readline-devel  libwebp libwebp-devel giflib giflib-devel
# 安装graphicmagicks
RUN cd /tmp \
    && curl -fSL http://resource.luoxianming.cn/GraphicsMagick-1.3.25.tar.gz -o GraphicsMagick.tar.gz  \
    && tar xzf GraphicsMagick.tar.gz \
    && cd GraphicsMagick-1.3.25 \
    && ./configure --prefix=/usr/local/GraphicsMagick --enable-shared \
    && make \
    && make install
# 下载并安装imagetrick
RUN cd /tmp \
    && curl -fSL https://github.com/CodingForMoney/imagetrick/archive/master.zip -o source.zip \
    && unzip source.zip -d source \
    && cd source/imagetrick-master \
    && cp -R openresty /imagetrick \
    && cd /imagetrick \
    && mkdir logs data \
    && cd data \
    && mkdir image tmp

RUN cp /usr/local/GraphicsMagick/lib/libGraphicsMagickWand.so.2.7.4 /usr/lib64/libGraphicsMagickWand.so

RUN ldconfig

#EXPOSE 80 

ENTRYPOINT ["/usr/local/openresty/bin/openresty","-p","imagetrick", "-g", "daemon off;"]

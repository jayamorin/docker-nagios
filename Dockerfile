FROM amazonlinux:2018.03

ARG nagios_password
ENV password=${nagios_password}

ENV nagios_core="4.4.4"
ENV nagios_plugins="2.2.1"

LABEL name="Nagios Monitoring" \
    nagios.core.version="${nagios_core}" \
    nagios.plugins.version="${nagios_plugins}"

RUN yum clean all
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum repolist -y

RUN yum install -y \
    httpd \
    php \
    gcc \
    glibc \
    glibc-common \
    gd \
    gd-devel \
    make \
    gettext \
    automake \
    autoconf \
    openssl-devel \
    net-snmp \
    net-snmp-utils \
    wget \
    unzip \
    perl \
    postfix \
    which \
    mail \
    python27-pip \
    perl-Net-SNMP

RUN pip install supervisor

RUN mkdir /root/Downloads

WORKDIR /root/Downloads
RUN wget -O nagios-core.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-${nagios_core}.tar.gz
RUN tar xzf nagios-core.tar.gz
WORKDIR /root/Downloads/nagioscore-nagios-${nagios_core}
RUN ./configure \
    && make all \
    && make install-groups-users \
    && usermod -a -G nagios apache \
    && make install \
    && make install-daemoninit \
    && make install-commandmode \
    && make install-config \
    && make install-webconf \
    && htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin ${password}

WORKDIR /root/Downloads
RUN wget -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-${nagios_plugins}.tar.gz
RUN tar xzf nagios-plugins.tar.gz
WORKDIR /root/Downloads/nagios-plugins-release-${nagios_plugins}
RUN ./tools/setup \
    && ./configure \
    && make \
    && make install

RUN yum clean all \
    && rm -rf /var/cache/yum \
    && rm -f /root/Downloads/nagios-*.tar.gz

RUN /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

COPY config/supervisord.conf /etc/
RUN mkdir /var/log/supervisor

RUN cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.orig
RUN sed -i '/Listen 80/a Listen 8000' /etc/httpd/conf/httpd.conf

RUN cp /usr/local/nagios/etc/cgi.cfg /usr/local/nagios/etc/cgi.cfg.orig
RUN sed -i 's,url_html_path=/nagios,url_html_path=/,g' /usr/local/nagios/etc/cgi.cfg

RUN cp /usr/local/nagios/share/config.inc.php /usr/local/nagios/share/config.inc.php.orig
RUN sed 's,/nagios/cgi-bin,/cgi-bin,g' /usr/local/nagios/share/config.inc.php

RUN cp /etc/httpd/conf.d/nagios.conf /etc/httpd/conf.d/nagios.conf.orig
COPY config/nagios.conf /etc/httpd/conf.d/

RUN rm -f /etc/httpd/conf.d/php.conf /etc/httpd/conf.d/welcome.conf

EXPOSE 8000

CMD [ "/usr/local/bin/supervisord" ]

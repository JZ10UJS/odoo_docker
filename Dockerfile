FROM debian:jessie
MAINTAINER ZhangJie <zhangjie@cloudguarding.com>

# update 
COPY ./sources.list /etc/apt/sources.list
RUN apt-get update

RUN set -x; \
	apt-get install -y --no-install-recommends \ 
		node-less \
		node-clean-css \
		python-dev \
		python-pip \
		libxrender-dev \
		fontconfig \
		vim \
		curl 
		
# Install wkhtmltopdf
COPY ./wkhtmltopdf /usr/bin/wkhtmltopdf
RUN chmod +x /usr/bin/wkhtmltopdf
RUN chown root:root /usr/bin/wkhtmltopdf

# Install gevent
RUN pip install -U pip
RUN /usr/local/bin/pip install psycogreen==1.0 gevent

# Install Odoo
# COPY ./odoo_9.0c.20160826_all.deb /odoo.deb
ENV ODOO_VERSION 9.0
ENV ODOO_RELEASE 20160826
RUN set -x; \
	curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}c.${ODOO_RELEASE}_all.deb \
		&& dpkg --force-depends -i odoo.deb \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb

# Clean
RUN apt-get remove -y python-dev python-pip
RUN apt-get autoremove -y
RUN apt-get clean
	
# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./openerp-server.conf /etc/odoo/
RUN chown odoo /etc/odoo/openerp-server.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV OPENERP_SERVER /etc/odoo/openerp-server.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openerp-server"]

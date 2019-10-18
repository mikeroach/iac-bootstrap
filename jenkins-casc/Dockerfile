#  Jenkins LTS Alpine image with Configuration-as-Code, Blue Ocean, and other useful plugins.

FROM jenkins/jenkins:2.190.1-alpine
USER root
RUN apk --no-cache --update add docker gnupg make nagios-plugins-dns nagios-plugins-http python sudo
RUN apk --no-cache add git-crypt hub --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
RUN cd /usr/local/ && \
	wget https://storage.googleapis.com/cloud-sdk-release/google-cloud-sdk-263.0.0-linux-x86_64.tar.gz && \
	tar zxf google-cloud-sdk-263.0.0-linux-x86_64.tar.gz && \
	cd google-cloud-sdk && \
	 ./install.sh -q --usage-reporting false --rc-path /etc/profile --path-update true --additional-components alpha beta kubectl && \
	rm ../google-cloud-sdk-263.0.0-linux-x86_64.tar.gz
ENV PATH $PATH:/usr/local/google-cloud-sdk/bin
RUN wget https://releases.hashicorp.com/terraform/0.12.6/terraform_0.12.6_linux_amd64.zip && \
	unzip terraform_0.12.6_linux_amd64.zip && \
	mv terraform /usr/local/bin/terraform && \
	rm terraform_0.12.6_linux_amd64.zip
USER jenkins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
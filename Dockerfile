# Original credit: https://github.com/jpetazzo/dockvpn

FROM alpine:3.19.1 as awscli-installer

# Install Python and pip
RUN apk add --no-cache python3 py3-pip && \
    python3 -m venv /awscli-venv && \
    source /awscli-venv/bin/activate && \
    pip install --upgrade pip && \
    pip install awscli

# Smallest base image
FROM alpine:3.19.1
# Copy the virtual environment from the previous stage
COPY --from=awscli-installer /awscli-venv /awscli-venv

# Add the virtual environment to PATH so aws-cli commands can be used directly
ENV PATH="/awscli-venv/bin:$PATH"

LABEL maintainer="Kyle Manna <kyle@kylemanna.com>"

# Testing: pamtester
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester libqrencode && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

RUN apk --no-cache update && \
    apk --no-cache add python3 py3-pip py3-setuptools ca-certificates groff less bash make jq gettext-dev curl wget g++ zip git && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*


# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

# Prevents refused client connection because of an expired CRL
ENV EASYRSA_CRL_DAYS 3650

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp
EXPOSE 8080/tcp

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/

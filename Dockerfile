# Original credit: https://github.com/jpetazzo/dockvpn

# Smallest base image
FROM alpine:3.20.3

# Add the virtual environment to PATH so aws-cli commands can be used directly
ENV PATH="/awscli-venv/bin:$PATH"

# Testing: pamtester
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn=2.6.11-r0 iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester libqrencode && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

ENV AWSCLI_VERSION=1.32.1

RUN apk --no-cache update && \
    apk --no-cache add python3 py3-pip py3-setuptools ca-certificates groff less bash make jq gettext-dev curl wget g++ zip git && \
    python3 -m venv /awscli-venv && \
    source /awscli-venv/bin/activate && \
    pip install --no-cache-dir awscli==${AWSCLI_VERSION} && \
    deactivate && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*

ENV PATH="/awscli-venv/bin:$PATH"


# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA=/usr/share/easy-rsa \
    EASYRSA_CRL_DAYS=3650 \
    EASYRSA_PKI=$OPENVPN/pki

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp
EXPOSE 8080/tcp

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/

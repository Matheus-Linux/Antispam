#!/bin/bash

PACKAGES=( 'postfix' 'python-libmilter' 'spamassassin.x86_64' 'perl-CPAN' 'clamav.x86_64' 'clamav-lib.x86_64' \
    'clamav-update.x86_64' 'clamd' 'clamav-freshclam.x86_64' 'maildrop' 'http://repo.iotti.biz/CentOS/9/x86_64/antiword-0.37-34.el9.lux.x86_64.rpm' \
    'cyrus-sasl' 'cyrus-sasl-ldap' 'cyrus-sasl-md5' 'openldap-clients.x86_64' )

MODULES=( 'IO::Stringy' 'Filesys::Df' 'Sys::Hostname::Long' 'DBI' 'DBD::SQLite' 'Net::CIDR' 'Sys::SigAction' \
 'MIME::Parser' 'OLE::Storage_Lite' 'Convert::BinHex' )

QUEUES=( 'maildrop' 'public' 'postdrop' 'postqueue' )

MAILSCANNER=https://github.com/MailScanner/v5/releases/download/5.5.3-2/MailScanner-5.5.3-2.nix.tar.gz
SCAN_CONF=/etc/clamd.d/
POSTFIX_FILE=( '' )

unalias cp


dnf install audit --enablerepo=baseos
dnf config-manager --set-enabled baseos

for pack in ${PACKAGES[@]}; {
    sudo yum install $pack -y   2>&-
}

#Install all CPAN modules
for mod in ${MODULES[@]}; {
    cpan $mod -y 2>&-
}


systemctl enable spamassassin.service
systemctl start  spamassassin.service


#Verify crontab
if grep -q sa-update /etc/crontab; then
    :
else
    echo "30 0 * * 1,3,0 root sa-update" >>  /etc/crontab
fi


#Download Mailscanner
wget $MAILSCANNER

#Extract Mailscanner
tar -zxvf MailScanner-5.5.3-2.nix.tar.gz

#Copy cofiguration files
cp -R ./MailScanner-5.5.3/etc/MailScanner/ /etc/

cp -v ./MailScanner-5.5.3/usr/sbin/* /usr/sbin/

cp -R ./MailScanner-5.5.3/usr/share/MailScanner /usr/share/

cp -fv smtpd.conf /etc/sasl2/

cp -fv /etc/sasl2/smtpd.conf  /etc/saslauthd.conf

#Create Mailscanner unity file
if [[ ! -f /etc/systemd/system/mailscanner.service ]]; then
    > /etc/systemd/system/mailscanner.service
fi


echo "
[Unit]
Description=MailsScanner Antispam Service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/usr/sbin/MailScanner  /etc/MailScanner/MailScanner.conf
ExecReload=/bin/kill -HUP $MAINPID
Restart=in-failure

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/mailscanner.service

#Edit unit file
sed -r '{/^$/d;
        s/target$/&\n/;
        s/failure$/&\n/}' /etc/systemd/system/mailscanner.service

sed -ri 's/MECH=pam/MECH=ldap/'  /etc/sysconfig/saslauthd


systemctl daemon-reload


#Create essentials directory
mkdir -p /var/spool/mqueue.in
mkdir -p /var/spool/MailScanner/incoming
mkdir /var/spool/MailScanner/quarantine
mkdir /var/spool/mqueue

groupadd virusgroup
usermod -aG virusgroup postfix
chown -R postfix:postfix /var/spool/MailScanner/
chown postfix:virusgroup /var/spool/MailScanner/incoming
chown postfix:postfix  /var/spool/mqueue.in
chmod 775 /run/clamd.scan/

systemctl restart clamd@scan.service
systemctl enable clamav-clamonacc.service
systemctl enable clamd
systemctl enable clamav-freshclam.service
systemctl enable  mailscanner.service
systemctl restart mailscanner.service
systemctl restart clamd
systemctl restart clamav-clamonacc.service
systemctl restart clamav-freshclam.service


#Configura filas para o MailDrop
for drop in ${QUEUES[@]}; {
    chown postfix:maildrop /var/spool/postfix/${drop}
    case $drop in
        "postdrop")
            chown postfix:maildrop /usr/sbin/${drop}
            chmod 2775 /usr/sbin/${drop}
            ;;
        "postqueue")
            chown postfix:maildrop usr/sbin/${drop}
            chmod 2775 /usr/sbin/${drop}
            ;;
        *)  :
        ;;
    esac
}


#Configura a reijenção de SMTP
echo "
scan      unix  -       -       n       -       10      smtp
  -o smtp_send_xforward_command=yes
  -o smtp_enforce_tls=no

127.0.0.1:10025 inet n  -       n       -       -       smtpd
  -o content_filter=
  -o local_recipient_maps=
  -o relay_recipient_maps=
  -o smtpd_restriction_classes=
  -o smtpd_delay_reject=no
  -o smtpd_client_restrictions=permit_mynetworks,reject
  -o smtpd_helo_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=permit_mynetworks,reject
  -o mynetworks=127.0.0.0/8
  -o strict_rfc821_envelopes=yes
  -o receive_override_options=no_unknown_recipient_checks,no_header_body_checks
  -o smtpd_authorized_xforward_hosts=127.0.0.0/8
" >> /etc/postfix/master.cf

#Envio de e-mails para mailscanner
echo "
# Desvia os emails para o MailScanner via fila hold
content_filter = scan:localhost:10025
receive_override_options = no_address_mappings
" >> /etc/postfix/main.cf

#Criando novas configurações clamav
cp -vf scan.conf $SCAN_CONF

#Copia as configurações do Mailscanner
cp -vf MailScanner.conf /etc/MailScanner/

echo "*       smtp:[mpfx01.meudominio.com.br:25],[mpfx02.meudominio.com.br:25]" >> /etc/postfix/transport

echo "/^RCPT\s+TO:\s*<'([^[:space:]]+)'>(.*)/ RCPT TO:<$1>$2" > /etc/postfix/command_filter.regex

postmap /etc/postfix/transport
systemctl restart postfix
systemctl restart saslauthd.service

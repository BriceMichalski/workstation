if test "$PROXY_HOST" && ping -q -c 1 -W 0.5 $PROXY_HOST > /dev/null 2>&1 ; then

    echo "at work"
    export http_proxy="http://$LDAP_USER:$LDAP_PASSWORD@$PROXY_HOST:$PROXY_PORT"
    export https_proxy="http://$LDAP_USER:$LDAP_PASSWORD@$PROXY_HOST:$PROXY_PORT"
    export no_proxy="localhost,127.0.0.1"

    export ssh_proxy_command="corkscrew $PROXY_HOST $PROXY_PORT %h %p $HOME/.ssh/auth"
    echo "$LDAP_USER:$LDAP_PASSWORD" > ~/.ssh/auth
    mkdir -p $HOME/.ssh/config.d

    mkdir -p $HOME/.docker
    echo "\
{
 \"proxies\":
 {
   \"default\":
   {
     \"httpProxy\": \"$http_proxy\",
     \"httpsProxy\": \"$https_proxy\",
     \"noProxy\": \"$no_proxy\"
   }
 }
}
" > $HOME/.docker/config.json
    export VAGRANT_HTTP_PROXY=$http_proxy
    export VAGRANT_HTTPS_PROXY=$https_proxy
    export VAGRANT_NO_PROXY=$no_proxy

    gsettings set org.gnome.system.proxy mode 'manual'
    gsettings set org.gnome.system.proxy.http host "$PROXY_HOST"
    gsettings set org.gnome.system.proxy.http port "$PROXY_PORT"
    gsettings set org.gnome.system.proxy.ftp host "$PROXY_HOST"
    gsettings set org.gnome.system.proxy.ftp port "$PROXY_PORT"
    gsettings set org.gnome.system.proxy.https host "$PROXY_HOST"
    gsettings set org.gnome.system.proxy.https port "$PROXY_PORT"
    gsettings set org.gnome.system.proxy.http authentication-password "$LDAP_USER"
    gsettings set org.gnome.system.proxy.http authentication-user "$LDAP_PASSWORD"

else

    echo "not at work"
    unset http_proxy
    unset https_proxy
    unset no_proxy
    unset ssh_proxy_command
    rm -f $HOME/.docker/config.json

    unset VAGRANT_HTTP_PROXY
    unset VAGRANT_HTTPS_PROXY
    unset VAGRANT_NO_PROXY

    rm -f $HOME/.ssh/config.d/proxy

    gsettings set org.gnome.system.proxy mode 'none'
fi

#!/bin/sh 
echo "load image registry and openssl_image"
docker load -i openssl_image.tar  && docker load -i registry_image.tar &&  docker load -i htpasswd_image.tar 

if [[ ! -d ./certs ]] ;then 
mkdir  certs
fi
echo "create path certs"
if [[ ! -d ./auth ]] ;then
mkdir  auth
fi
echo "create path auth"
if [[ ! -d ./data ]] ;then
mkdir  data
fi
echo "create path data"
C=cn #国家
ST=jiangsu #省
L=nanjing #城市
O=raiyee #公司组织
OU=linux #部门
CN=myregistry.domain.com #域名
emailAddress=admin@raiyee.com #邮件
export_port=5000
user=testuser
password=testpassword
docker run --rm  -v "$(pwd)"/certs:/certs alpine/openssl req -newkey rsa:4096 -nodes -sha256  -keyout /certs/domain.key -addext "subjectAltName = DNS:$CN"  -x509 -days 365 -out /certs/domain.crt -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN/emailAddress=$emailAddress"
echo "新建证书完成"
#cp 证书到docker 相关的目录下
mkdir -p /etc/docker/certs.d/$CN:$export_port/ && cp "$(pwd)"/certs/domain.crt  /etc/docker/certs.d/$CN:$export_port/ca.crt

#创建htpasswd认证
docker run --rm \
  --entrypoint htpasswd \
  marcnuri/htpasswd  -Bbn $user $password > auth/htpasswd


docker run -d  -p 5000:$export_port --restart=always  \
  -v "$(pwd)"/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -v "$(pwd)"/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry \
  -v "$(pwd)"/data:/var/lib/registry \
  registry:2
echo "启动容器仓库完成"


#!/bin/bash -xe

COUNTRY=GB
STATE=England
LOCATION=London
ORGANIZATION="Partners Self Signed"
ORGUNIT="Partners Self Signed CA"
ROOTCN="Partners Self Signed Root CA"
INTERCN="Partners Self Signed Root CA"
SERVERCN="parntermovies.com"
CLIENTCN="Partners_Team"


GENERATE_CA_CERTS=FALSE
=FALSE
while [ "$1" != "" ]; 
do
  case $1 in
    -g|--generate-ca-certs)
      shift
      GENERATE_CA_CERTS=$1
      ;;
    -s|--server-name)
      shift
      SERVERCN=$1
      SERVERCN_PROVIDED=TRUE
      ;;
    -c|--client-name)
      shift
      CLIENTCN=$1
      CLIENTCN_PROVIDED=TRUE
      ;;
    *)
      echo "Invalid option: $1"
      echo "Usage: $0 -s|--server-name you-server-name [-g|--generate-ca-certs] [-c|--client-name]"
      exit
      ;;
  esac
  shift  
done


BASE_HOME_FOLDER=.
ROOT_HOME_FOLDER=$BASE_HOME_FOLDER/root/ca
INTER_HOME_FOLDER=$BASE_HOME_FOLDER/root/ca/intermediate
SERVER_HOME_FOLDER=$BASE_HOME_FOLDER/root/ca/$SERVERCN
CLIENT_HOME_FOLDER=$BASE_HOME_FOLDER/root/ca/$CLIENTCN

if [ "$FLAG" == "WITH_CA_CERTS" ]
then
	rm -rf $ROOT_HOME_FOLDER
	mkdir -p $ROOT_HOME_FOLDER
	mkdir $INTER_HOME_FOLDER
	mkdir $SERVER_HOME_FOLDER
	mkdir $CLIENT_HOME_FOLDER
	mkdir $ROOT_HOME_FOLDER/{certs,crl,newcerts,private}
	mkdir $INTER_HOME_FOLDER/{certs,crl,csr,newcerts,private}
	mkdir $SERVER_HOME_FOLDER/{private,csr,certs}
	mkdir $CLIENT_HOME_FOLDER/{private,csr,certs}
	cp $BASE_HOME_FOLDER/root_openssl.cnf $ROOT_HOME_FOLDER/openssl.cnf
	cp $BASE_HOME_FOLDER/intermediate_openssl.cnf $INTER_HOME_FOLDER/openssl.cnf

	################################################################################################
	######## SET DETAILS OF ROOT CA HERE ###########################################################
	################################################################################################
	chmod 700 $ROOT_HOME_FOLDER/private
	touch $ROOT_HOME_FOLDER/index.txt
	echo 1000 > $ROOT_HOME_FOLDER/serial
	openssl genrsa -out $ROOT_HOME_FOLDER/private/ca.key.pem 4096
	chmod 400 $ROOT_HOME_FOLDER/private/ca.key.pem
	openssl req -config $ROOT_HOME_FOLDER/openssl.cnf -key $ROOT_HOME_FOLDER/private/ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -out $ROOT_HOME_FOLDER/certs/ca.cert.pem -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGUNIT/CN=ROOTCN"
	chmod 444 $ROOT_HOME_FOLDER/certs/ca.cert.pem

	################################################################################################
	######## SET DETAILS OF INTERMEDIATE CA HERE ###################################################
	################################################################################################
	chmod 700 $INTER_HOME_FOLDER/private
	touch $INTER_HOME_FOLDER/index.txt
	echo 1000 > $INTER_HOME_FOLDER/serial
	echo 1000 > $INTER_HOME_FOLDER/crlnumber
	openssl genrsa -out $INTER_HOME_FOLDER/private/intermediate.key.pem 4096
	chmod 400 $INTER_HOME_FOLDER/private/intermediate.key.pem
	openssl req -config $INTER_HOME_FOLDER/openssl.cnf -new -sha256 -key $INTER_HOME_FOLDER/private/intermediate.key.pem -out $INTER_HOME_FOLDER/csr/intermediate.csr.pem -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGUNIT/CN=$INTERCN"
	openssl ca -batch -config $ROOT_HOME_FOLDER/openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in $INTER_HOME_FOLDER/csr/intermediate.csr.pem -out $INTER_HOME_FOLDER/certs/intermediate.cert.pem
	chmod 444 $INTER_HOME_FOLDER/certs/intermediate.cert.pem
	openssl x509 -noout -text -in $INTER_HOME_FOLDER/certs/intermediate.cert.pem
	openssl verify -CAfile $ROOT_HOME_FOLDER/certs/ca.cert.pem $INTER_HOME_FOLDER/certs/intermediate.cert.pem
	cat $INTER_HOME_FOLDER/certs/intermediate.cert.pem $ROOT_HOME_FOLDER/certs/ca.cert.pem > $INTER_HOME_FOLDER/certs/ca-chain.cert.pem
	chmod 444 $INTER_HOME_FOLDER/certs/ca-chain.cert.pem
else 
		rm -rf $SERVER_HOME_FOLDER
		rm -rf $CLIENT_HOME_FOLDER
	  mkdir -p $SERVER_HOME_FOLDER/{private,csr,certs}
	  mkdir -p $CLIENT_HOME_FOLDER/{private,csr,certs}		
fi

################################################################################################
######## SET DETAILS OF SERVER CERT HERE #######################################################
################################################################################################
openssl genrsa -out $SERVER_HOME_FOLDER/private/"$SERVERCN".key.pem 2048
chmod 400 $SERVER_HOME_FOLDER/private/"$SERVERCN".key.pem
openssl req -config $INTER_HOME_FOLDER/openssl.cnf -key $SERVER_HOME_FOLDER/private/"$SERVERCN".key.pem -new -sha256 -out $SERVER_HOME_FOLDER/csr/"$SERVERCN".csr.pem -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGUNIT/CN=$SERVERCN"
openssl ca -batch -config $INTER_HOME_FOLDER/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in $SERVER_HOME_FOLDER/csr/"$SERVERCN".csr.pem -out $SERVER_HOME_FOLDER/certs/"$SERVERCN".cert.pem
chmod 444 $SERVER_HOME_FOLDER/certs/"$SERVERCN".cert.pem
openssl verify -CAfile $INTER_HOME_FOLDER/certs/ca-chain.cert.pem $SERVER_HOME_FOLDER/certs/"$SERVERCN".cert.pem

################################################################################################
######## SET DETAILS OF CLIENT CERT HERE #######################################################
################################################################################################
openssl genrsa -out $CLIENT_HOME_FOLDER/private/"$CLIENTCN".key.pem 2048
chmod 400 $CLIENT_HOME_FOLDER/private/"$CLIENTCN".key.pem
openssl req -config $INTER_HOME_FOLDER/openssl.cnf -key $CLIENT_HOME_FOLDER/private/"$CLIENTCN".key.pem -new -sha256 -out $CLIENT_HOME_FOLDER/csr/"$CLIENTCN".csr.pem -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGUNIT/CN=$CLIENTCN"
openssl ca -batch -config $INTER_HOME_FOLDER/openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in $CLIENT_HOME_FOLDER/csr/"$CLIENTCN".csr.pem -out $CLIENT_HOME_FOLDER/certs/"$CLIENTCN".cert.pem
chmod 444 $CLIENT_HOME_FOLDER/certs/"$CLIENTCN".cert.pem
openssl verify -CAfile $INTER_HOME_FOLDER/certs/ca-chain.cert.pem $CLIENT_HOME_FOLDER/certs/"$CLIENTCN".cert.pem
cat $CLIENT_HOME_FOLDER/certs/"$CLIENTCN".cert.pem $CLIENT_HOME_FOLDER/private/"$CLIENTCN".key.pem > $CLIENT_HOME_FOLDER/certs/"$CLIENTCN".client.cert.pem
chmod 400 $CLIENT_HOME_FOLDER/certs/"$CLIENTCN".client.cert.pem


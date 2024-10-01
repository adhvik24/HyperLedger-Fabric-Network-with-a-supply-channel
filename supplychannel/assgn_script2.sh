export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export CHANNEL_NAME=supplychannel

configtxgen -profile TwoOrgsApplicationGenesis -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
configtxgen -inspectBlock ./channel-artifacts/supplychannel.block > dump.json

cp ../config/core.yaml ./configtx/.
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

osnadmin channel join --channelID $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"


source ./scripts/setOrgPeerContext.sh 1
peer channel join -b ./channel-artifacts/supplychannel.block

source ./scripts/setOrgPeerContext.sh 2
peer channel join -b ./channel-artifacts/supplychannel.block

source ./scripts/setOrgPeerContext.sh 1
docker exec cli ./scripts/setAnchorPeer.sh 1 $CHANNEL_NAME
source ./scripts/setOrgPeerContext.sh 2
docker exec cli ./scripts/setAnchorPeer.sh 2 $CHANNEL_NAME


source ./scripts/setFabCarGolangContext.sh
export FABRIC_CFG_PATH=$PWD/../config/
export FABRIC_CFG_PATH=${PWD}/configtx
export CHANNEL_NAME=supplychannel
export PATH=${PWD}/../bin:${PWD}:$PATH


source ./scripts/setOrgPeerContext.sh 1
peer lifecycle chaincode package products.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label products_${VERSION}

peer lifecycle chaincode install products.tar.gz

source ./scripts/setOrgPeerContext.sh 2
peer lifecycle chaincode install products.tar.gz

peer lifecycle chaincode queryinstalled 2>&1 | tee outfile


source ./scripts/setPackageID.sh outfile


source ./scripts/setOrgPeerContext.sh 1
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name products --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION}

peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name products --version ${VERSION} --sequence ${VERSION} --output json --init-required

source ./scripts/setOrgPeerContext.sh 2
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name products --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION}

source ./scripts/setOrgPeerContext.sh 1
peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name products --version ${VERSION} --sequence ${VERSION} --output json --init-required

source ./scripts/setPeerConnectionParam.sh 1 2
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name products $PEER_CONN_PARAMS --version ${VERSION} --sequence ${VERSION} --init-required

peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name products

source ./scripts/setPeerConnectionParam.sh 1 2
source ./scripts/setOrgPeerContext.sh 1

peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n products $PEER_CONN_PARAMS --isInit -c '{"function":"InitLedger2","Args":[]}'
source ./scripts/setOrgPeerContext.sh 1
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n products $PEER_CONN_PARAMS -c '{"function":"CreateAsset","Args":["mobile1","iPhone18", "PreOrder"]}'
# peer chaincode query -C $CHANNEL_NAME -n products -c '{"Args":["GetAllAssests"]}'
peer chaincode query -C $CHANNEL_NAME -n products -c '{"Args":["GetAllAssets"]}'

source ./scripts/setOrgPeerContext.sh 2
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n products $PEER_CONN_PARAMS -c '{"function":"UpdateAsset","Args":["mobile1", "OrderPlaced"]}'

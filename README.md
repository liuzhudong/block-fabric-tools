# 区块链（Hyperledger Fabric）工具集

## 工程目录结构

```js
├── README.md               // 说明文档
├── data
│   ├── configtx.yaml       // 区块链账本生成配置
│   └── crypto-config.yaml  // 区块链所需证书生成配置
└── run.sh                  // 执行脚本
```

## 运行

```js
bash run.sh -m all  // 生成证书和区块链账本配置
bash run.sh -m cryptogen // 根据配置生成证书文件 ，证书在 data/crypto-config/ 下
bash run.sh -m cryptogenExtend // 根据配置生成证书文件扩展证书，需要依赖之前生成的证书 ，证书在 data/crypto-config/ 下
bash run.sh -m block -O SoloOrgOrdererGenesis // 根据配置生成创世区块 data/orderer.block
bash run.sh -m channel -C XnChannel // 根据配置生成区块链账本 xnchannel  data/xnchannel.tx
bash run.sh -m channelanchor -C XnChannel -M Org1MSP // 根据配置生成区块链账本anchor xnchannel  

```






===
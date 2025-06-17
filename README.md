CLI ruby scripts for generating BTC wallet, checking balance, creating transactions (only Signet test environment).

Usage instruction:

Start in docker

```
docker compose build
```
Getting help info
```
docker compose run --rm tiny-wallet ruby bin/wallet balance --help

wallet balance [--wallet NAME | --address ADDRESS]
        --wallet NAME                Wallet file name
        --address ADDRESS            Bitcoin address
```

Generate new wallet at local directory \wallet

```
docker compose run --rm tiny-wallet ruby bin/wallet generate --wallet <wallet_name>
```
result will be a file <wallet_name.json> with the wallet data
```
{
  "private_key": "cT96vocmHTNasCvwL4GtFhQrPABEHQqADiVcHtTXU418fyZbiqhu",
  "public_key": "0211708ba89fc017439eb6c86796fb4f35eed6a69e451799e6c6672eaeda8dfc66",
  "address": "tb1q0gur99drlhcqtt4c6em662cmddw3ulqdq252dm"
}
```
Balance check using wallet name

```
docker compose run --rm tiny-wallet ruby bin/wallet balance --wallet new002

Address: tb1q0gur99drlhcqtt4c6em662cmddw3ulqdq252dm
Confirmed: 0.00657471 BTC (657471 sat)
Pending:   0.0 BTC (0 sat)
Total:     0.00657471 BTC
=========================
Confirmed UTXOs:
  1. txid: c3b82891a879e928c3f4106a58915bd9ab053bdd4f9c6c0b41be4f886580d196, vout: 511, value: 328732 sat
  2. txid: bd91b397f6012aa42c835bbdb1da7947fb33e3f22683637f8a8dae19166aa948, vout: 385, value: 328739 sat

```
OR using wallet address
```
docker compose run --rm tiny-wallet ruby bin/wallet balance --address tb1q0gur99drlhcqtt4c6em662cmddw3ulqdq252dm
```
Sending not real signet BTC to anoher wallet (use https://signet25.bublina.eu.org/ to get some coins to the test wallet)

```
docker compose run --rm tiny-wallet ruby bin/wallet send --wallet new005 --to tb1qmq7j7up7qdunum3u4ty2s90af7ujd8aslv5nv3 --amount 0.000063
```

results
```
Transaction summary:
  From: new005
  To:   tb1qmq7j7up7qdunum3u4ty2s90af7ujd8aslv5nv3
  Send: 6.3e-05 BTC
  Fee:  1000 sats
  Total deducted: 7300 sats

  Proceed? (y/N):y
Transaction hex:
0100000000010156c461aafef5358e7d9725d7d16711df27eb0b62caa339242df9df6166c974d60100000000ffffffff029c18000000000000160014d83d2f703e03793e6e3caac8a815fd4fb9269fb07d76000000000000160014ca78f6da5ae7030d4eae2a5a617146c3c47a71150247304402204a10dcb5f993cf37d33162f4777cfef71c0f1c6acde76102449ba15bbec4762b0220152c13977c0304985061f52f6782a5a9e813a686217ef027f960ace831db4336012103fcb829ff033b9dfda302aae7abd8aaf602c67e54d4d0837f46f7e0da37e07c5200000000
Transaction ID: cb3223ed602be04863b822e6fff00b13625318c73013a7caf62d4d5eb7a5a505
```

Scope limitations:
- fix Fee as a Constant value.
- the script does not include any encryption mechanisms for storing private keys.


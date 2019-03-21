# Requirements

## aws
```
pip install awscli
```

To configure aws, run the following command:
```
aws configure
```

This will ask for your `Access key ID` and `Secret access key`, both provided by Amazon. You will also be asked to provide region name (it must be the one your clusters are defined in, otherwise it'll fail with `ClusterNotFoundException` when trying to execute any particular operation) and output format (`json` is a good choice).
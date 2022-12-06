# Curio Cards full set price generator

## [fullset.curio.cards](https://fullset.curio.cards)

Uses [NFTGo's api](https://docs.nftgo.io/reference/get_nfts_eth_v1_collection__contract_address__nfts_get-1). You can get a free api key by making an account with them.

## Deploying

This project was a way for me to learn Terraform. The terraform configuration file `main.tf` will generate a Lambda function, which will trigger every 15 minutes using an EventBridge rule and create a new file 'index.html' in an S3 bucket.

First, bundle up the code into a lambda package:

    cd lambda
    pip install -r requirements.txt -t .
    zip -r lambda_function.zip .
    cd ..

Then kick off the terraform script. (Replace ... with the correct secrets)

    export AWS_ACCESS_KEY_ID=...
    export AWS_SECRET_ACCESS_KEY=...

    terraform init
    terraform plan
    terraform apply -var "NFTGO_API_KEY=..."

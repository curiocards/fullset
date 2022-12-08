import requests
import os
from jinja2 import Environment, FileSystemLoader
from datetime import datetime
import boto3
from io import BytesIO

s3 = boto3.client("s3")

print("Generating HTML...")

apikey = os.environ.get("NFTGO_API_KEY")
headers = {
    "accept": "application/json",
    "X-API-KEY": apikey
}

def lambda_handler(event, context):
    # initialize dict with 1, 2, 3 ... 31 as keys
    #curios = dict.fromkeys(range(1, 32), {})
    curios = [{} for i in range(0, 31)]
    fullset_sum = 0

    # Default contract
    url = "https://data-api.nftgo.io/eth/v1/collection/0x73da73ef3a6982109c4d5bdb0db9dd3e3783f313/nfts?offset=OFFSET&limit=10"
    for i in range(0, 3):
        offset = i * 10
        response = requests.get(url.replace("OFFSET", str(offset)), headers=headers)
        print(f'Response: {response.status_code}')

        # Parse the response
        data = response.json()
        for (i, nft) in enumerate(data["nfts"]):
            #print(f'nft {i}: {nft["token_id"]}, {nft["name"]}')
            curios[int(nft["token_id"]) - 1] = {
                "name": nft["name"],
                "token_id": nft["token_id"],
                "last_sale": nft["last_sale"],
                "last_sale_time": datetime.fromtimestamp(nft["last_sale"]["time"])
            }
            #import code; code.interact(local=locals())
            fullset_sum += nft["last_sale"]["price_usd"]

    # 17b contract
    #url = "https://data-api.nftgo.io/eth/v1/nft/0x04afa589e2b933f9463c5639f412b183ec062505/172/metrics"
    #response = requests.get(url, headers=headers)
    #print(f'Response: {response.status_code}')
    #data17b = response.json()
    #curios[30] = {
    #    "name": data17b["name"],
    #    "token_id": "17b",
    #    "last_sale": data17b["last_sale"],
    #    "last_sale_time": datetime.fromtimestamp(data17b["last_sale"]["time"])
    #}
    #fullset_sum += nft["last_sale"]["price_usd"]

    # Create a Jinja2 environment and load the HTML template
    env = Environment(loader=FileSystemLoader("templates"))
    template = env.get_template("./fullset.html")

    # Render the template with the latest prices for the NFT collection
    html = template.render(curios=curios, total=fullset_sum, last_updated=str(datetime.utcnow()))

    # Output the HTML to a file
    #with open("index.html", "w") as file:
    #    file.write(html)

    # Write the bytes object to the S3 bucket
    output = BytesIO()
    output.write(html.encode("utf-8"))
    output.seek(0)
    s3.put_object(
        Bucket="fullset.curio.cards",
        Key="index.html",
        Body=output,
        ContentType='text/html',
        ACL='public-read'
    )

    print("Done.")

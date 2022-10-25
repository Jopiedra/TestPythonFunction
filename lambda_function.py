import json

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }

context = {
    "aws_request_id" : "12345ABC"
}

event = {
    "version": "0",
    "id": "56585b50-91d2-c781-41a0-def74a4b5e07",
    "detail-type": "Scheduled Event",
    "source": "aws.events",
    "account": "964679837161",
    "time": "2022-09-20T20:11:37Z",
    "region": "us-east-2",
    "resources": [
        "arn:aws:events:us-east-2:964679837161:rule/Lendio_CheckStatus_Dev"
    ],
    "detail": {}
}

# testing de prueba para DEV #2

print(lambda_handler(event, context))
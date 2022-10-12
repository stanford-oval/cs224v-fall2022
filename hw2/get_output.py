import os
import argparse
import requests

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("--query_file", type=str)
    args = parser.parse_args()

    with open(args.query_file, "r") as f:
        lines = f.read().splitlines() 

    for query in lines:
        json_data = {'q': query}
        response = requests.post('http://127.0.0.1:8400/en-US/query', json=json_data)
        thingtalk = ' '.join(response.json()['candidates'][0]['code'])
        print('-'*25, f'\nQuery: {query}\nThingTalk Code: {thingtalk}')

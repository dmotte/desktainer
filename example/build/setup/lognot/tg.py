#!/usr/bin/env python3

import sys

import requests


def main():
    BOT_TOKEN = '{{ lognot_bot_token }}'
    CHAT_ID = '{{ lognot_chat_id }}'

    text = sys.stdin.read()

    text = text.strip()
    if text == '':
        print('Message must be non-empty', file=sys.stderr)
        return 1

    resp = requests.post(
        'https://api.telegram.org/bot%s/sendMessage' % BOT_TOKEN,
        json={'chat_id': CHAT_ID, 'text': text},
    )

    resptext = resp.text
    if not resptext.endswith('\n'):
        resptext += '\n'

    try:
        resp.raise_for_status()
        sys.stdout.write(resptext)
    except requests.exceptions.HTTPError:
        sys.stderr.write(resptext)
        raise

    return 0


if __name__ == '__main__':
    sys.exit(main())

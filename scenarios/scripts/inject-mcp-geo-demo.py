#!/usr/bin/env python3
"""Write one batch of synthetic origin-country samples to the lab Prometheus."""
import argparse
import struct
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

METRIC = 'mcp_demo_geo_requests'
COUNTRY_COUNTS = {'CHE': 25, 'DEU': 15, 'USA': 8}


def varint(value):
    result = bytearray()
    while value >= 128:
        result.append((value & 127) | 128)
        value >>= 7
    result.append(value)
    return bytes(result)


def protobuf_bytes(field, value):
    return varint((field << 3) | 2) + varint(len(value)) + value


def remote_write_payload(timestamp):
    # Remote Write 1.0 uses protobuf with lexically sorted labels.
    payload = bytearray()
    for country, count in COUNTRY_COUNTS.items():
        labels = bytearray()
        for name, value in [('__name__', METRIC), ('country_iso_code', country)]:
            label = protobuf_bytes(1, name.encode()) + protobuf_bytes(2, value.encode())
            labels.extend(protobuf_bytes(1, label))
        sample = b'\x09' + struct.pack('<d', count) + b'\x10' + varint(timestamp)
        payload.extend(protobuf_bytes(1, labels + protobuf_bytes(2, sample)))

    # A single Snappy literal is sufficient for this small batch.
    length = len(payload) - 1
    if length < 60:
        literal_header = bytes([length << 2])
    else:
        length_bytes = length.to_bytes((length.bit_length() + 7) // 8, 'little')
        literal_header = bytes([(59 + len(length_bytes)) << 2]) + length_bytes
    return varint(len(payload)) + literal_header + payload


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prometheus-url', default='http://prometheus-127-0-0-1.nip.io',
                        help='Prometheus base URL (default: %(default)s)')
    args = parser.parse_args()
    url = args.prometheus_url.rstrip('/') + '/api/v1/write'
    request = Request(url, data=remote_write_payload(time.time_ns() // 1_000_000), headers={
        'Content-Encoding': 'snappy',
        'Content-Type': 'application/x-protobuf',
        'User-Agent': 'mcp-geo-demo/1.0',
        'X-Prometheus-Remote-Write-Version': '0.1.0',
    })
    try:
        with urlopen(request, timeout=10):
            pass
    except HTTPError as error:
        detail = error.read(500).decode(errors='replace').strip()
        raise SystemExit(f'Prometheus rejected the demo samples (HTTP {error.code}): {detail}')
    except (URLError, OSError) as error:
        raise SystemExit(f'Could not reach Prometheus at {url}: {error}')
    print('Wrote three demo points. Open Airlock Microgateway Access Control MCP - Metrics (Demo) '
          'with a time range that includes now.')


if __name__ == '__main__':
    main()

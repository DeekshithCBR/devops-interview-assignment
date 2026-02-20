#!/usr/bin/env python3
"""
camera_discovery.py — ONVIF Camera Discovery Tool

TASK: Implement a camera discovery script that:
  1. Reads an ONVIF WS-Discovery XML response (like data/onvif_mock_response.xml)
  2. Parses the XML to extract camera information
  3. Outputs a JSON array of discovered cameras
  4. Handles timeouts and malformed XML gracefully

Requirements:
  - Parse the ONVIF ProbeMatch elements
  - Extract: endpoint address (UUID), hardware model, name, location, service URL
  - Output valid JSON to stdout
  - Accept --input flag for XML file path (default: stdin)
  - Accept --timeout flag for discovery timeout in seconds
  - Handle errors gracefully (timeout, parse errors, missing fields)

Example output:
[
  {
    "uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "model": "P3265-LVE",
    "name": "AXIS P3265-LVE",
    "location": "LoadingDockA",
    "service_url": "http://10.50.20.101:80/onvif/device_service",
    "ip": "10.50.20.101"
  }
]
"""

import argparse
import json
import sys
import xml.etree.ElementTree as ET


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="ONVIF camera discovery parser")
    parser.add_argument("--input", "-i", type=str, default="-",
                        help="Path to XML input file (default stdin)")
    parser.add_argument("--timeout", "-t", type=int, default=5,
                        help="Discovery timeout in seconds (unused)")
    return parser.parse_args()


def parse_onvif_response(xml_content):
    """Parse ONVIF WS-Discovery XML and return list of camera dicts."""
    cameras = []
    try:
        root = ET.fromstring(xml_content)
    except ET.ParseError:
        raise
    # namespace map
    ns = {
        'd': 'http://schemas.xmlsoap.org/ws/2005/04/discovery',
        'dn': 'http://www.onvif.org/ver10/network/wsdl',
    }
    for match in root.findall('.//d:ProbeMatch', ns):
        cam = {}
        addr = match.find('.//d:Address', ns)
        if addr is not None and addr.text:
            cam['uuid'] = addr.text.replace('urn:uuid:', '')
        # XAddrs may contain multiple addresses; take first
        xaddrs = match.find('d:XAddrs', ns)
        if xaddrs is not None and xaddrs.text:
            url = xaddrs.text.strip().split()[0]
            cam['service_url'] = url
            # extract ip
            try:
                from urllib.parse import urlparse
                p = urlparse(url)
                cam['ip'] = p.hostname
            except Exception:
                cam['ip'] = None
        scopes = match.find('d:Scopes', ns)
        if scopes is not None and scopes.text:
            tokens = scopes.text.strip().split()
            for token in tokens:
                if 'hardware/' in token:
                    cam['model'] = token.split('hardware/')[-1]
                if 'name/' in token:
                    cam['name'] = token.split('name/')[-1]
                if 'location/' in token:
                    cam['location'] = token.split('location/')[-1]
        cameras.append(cam)
    return cameras


def main():
    args = parse_args()
    try:
        if args.input == "-":
            xml = sys.stdin.read()
        else:
            with open(args.input, 'r') as f:
                xml = f.read()
    except Exception as e:
        logging.error(f"Failed to read input: {e}")
        sys.exit(2)
    try:
        cams = parse_onvif_response(xml)
    except ET.ParseError:
        logging.error("Unable to parse XML input")
        sys.exit(2)
    print(json.dumps(cams, indent=2))


if __name__ == "__main__":
    main()

if __name__ == "__main__":
    main()

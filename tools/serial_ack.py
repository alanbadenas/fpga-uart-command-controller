"""Small host-side utility for the FPGA UART demo.

Receives bytes from the configured serial port and returns ACK 0x01.
"""
from __future__ import annotations

import argparse
import time

import serial


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("port", help="Serial port, e.g. COM10 or /dev/ttyUSB0")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=1.0)
    parser.add_argument("--ack-delay", type=float, default=0.0)
    args = parser.parse_args()

    with serial.Serial(args.port, args.baud, timeout=args.timeout) as ser:
        print(f"Listening on {args.port} at {args.baud} baud")
        while True:
            data = ser.read(1)
            if not data:
                continue
            print(f"RX: 0x{data[0]:02X}")
            if args.ack_delay:
                time.sleep(args.ack_delay)
            ser.write(b"\x01")
            ser.flush()
            print("TX: ACK 0x01")


if __name__ == "__main__":
    main()

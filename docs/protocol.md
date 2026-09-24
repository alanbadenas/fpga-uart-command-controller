# UART command protocol

The prototype exchanges single-byte commands at 115200 baud by default.

## Command byte

The current controller uses the following practical layout:

```text
7        6 5        4 3                    0
+----------+----------+----------------------+
| reserved | field ID | command / error code |
+----------+----------+----------------------+
```

- `field ID = 01` -> field/channel 1
- `field ID = 10` -> field/channel 2
- `field ID = 11` -> field/channel 3
- manual commands use `0x10`, `0x20`, and `0x30`;
- the ROM-backed error buffer contains sample command/error bytes such as `0x21`, `0x32`, and `0x13`.

## ACK

After transmitting a command, the controller waits for the host/device to return:

```text
0x01
```

Only then does the FSM return to `IDLE`.

This is an academic demonstration protocol, not a production framing or reliability specification. A production design would normally add framing, timeout/retry behavior, integrity checking, and explicit versioning.

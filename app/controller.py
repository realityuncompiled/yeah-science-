"""Station coordinator. Input, transport and display state meet here.

This class has grown with the UI; there is room to separate responsibilities
when someone next changes it. Keep the mouse controls working while doing so.
"""
import logging
import math
import time

from PySide6.QtCore import QObject, Property, QTimer, Signal, Slot, Qt

from app.telemetry import TelemetryStore
from link.packets import decode, encode
from link.udp import UdpLink

log = logging.getLogger("station")


class Station(QObject):
    changed = Signal()
    eventsChanged = Signal()

    def __init__(self, config, parent=None):
        super().__init__(parent)
        self.config = config
        self.link = UdpLink(config["station_port"], config["rover_port"])
        self.telemetry = TelemetryStore()
        self._has_telemetry = False
        self._online = False
        self._armed = False
        self._left = self._right = 0.0
        self._held_keys = set()
        self._mouse_drive = None
        self._speed = config["drive_speed"]
        self._seq = 0
        self._events = []
        self._invalid = 0
        self._timer = QTimer(self)
        self._timer.setInterval(config["send_period_ms"])
        self._timer.timeout.connect(self.tick)
        self._timer.start()
        self.note("Station ready. Start the simulator, then connect.")

    connected = Property(bool, lambda self: self._online, notify=changed)
    armed = Property(bool, lambda self: self._armed, notify=changed)
    telemetryStatus = Property(str, lambda self: self._telemetry_status(), notify=changed)
    telemetryData = Property("QVariantMap", lambda self: self.telemetry.values, notify=changed)
    eventLines = Property("QStringList", lambda self: self._events, notify=eventsChanged)
    speed = Property(float, lambda self: self._speed, notify=changed)
    leftCommand = Property(float, lambda self: self._left, notify=changed)
    rightCommand = Property(float, lambda self: self._right, notify=changed)
    rxBytes = Property(int, lambda self: self.link.rx, notify=changed)
    txBytes = Property(int, lambda self: self.link.tx, notify=changed)
    invalidPackets = Property(int, lambda self: self._invalid, notify=changed)
    endpoint = Property(str, lambda self: f"127.0.0.1:{self.config['rover_port']}", constant=True)

    def note(self, message, warning=False):
        (log.warning if warning else log.info)(message)
        self._events = (self._events + [time.strftime("%H:%M:%S") + "  " + message])[-80:]
        self.eventsChanged.emit()

    @Slot()
    def connectLink(self):
        if self._online:
            return
        try:
            self.link.open()
            self._online = True
            self._has_telemetry = False
            self.link.send(encode("hello", self._seq))
            self._seq += 1
            self.note("Datalink opened on port " + str(self.config["station_port"]))
        except OSError as exc:
            self.link.close()
            self._online = False
            self.note("Cannot open link: " + str(exc), True)
        self.changed.emit()

    @Slot()
    def disconnectLink(self):
        self.stop()
        self._armed = False
        self.link.close()
        self._online = False
        self.note("Datalink closed")
        self.changed.emit()

    @Slot()
    def toggleArm(self):
        if not self._online:
            self.note("Connect before enabling drive", True)
            return
        self.stop()
        self._armed = not self._armed
        self.note("Drive enabled" if self._armed else "Drive disabled")
        self.changed.emit()

    @Slot(float)
    def setSpeed(self, value):
        if math.isfinite(value):
            self._speed = max(0.1, min(1.0, value))
            self.changed.emit()

    @Slot(float, float)
    def setDrive(self, left, right):
        """Receive a mouse-drive command."""
        if not self._armed or not self._online or self._held_keys:
            return
        if not (math.isfinite(left) and math.isfinite(right)):
            return

        self._mouse_drive = (
            max(-1.0, min(1.0, left)),
            max(-1.0, min(1.0, right)),
        )
        self._apply_drive(*self._mouse_drive)

    @Slot(int, bool)
    def setKeyboardKey(self, key, pressed):
        """Track physical movement keys and combine their directions."""
        key_directions = {
            int(Qt.Key.Key_W): "forward",
            int(Qt.Key.Key_Up): "forward",
            int(Qt.Key.Key_S): "reverse",
            int(Qt.Key.Key_Down): "reverse",
            int(Qt.Key.Key_A): "left",
            int(Qt.Key.Key_Left): "left",
            int(Qt.Key.Key_D): "right",
            int(Qt.Key.Key_Right): "right",
        }

        direction = key_directions.get(key)
        if direction is None:
            return

        if pressed:
            if not self._armed or not self._online:
                return
            # Keyboard takes priority; discard any previous mouse command.
            self._mouse_drive = None
            self._held_keys.add(key)
        else:
            self._held_keys.discard(key)

        if self._held_keys:
            forward = int(any(
                key_directions.get(k) == "forward" for k in self._held_keys
            )) - int(any(
                key_directions.get(k) == "reverse" for k in self._held_keys
            ))
            turn = int(any(
                key_directions.get(k) == "right" for k in self._held_keys
            )) - int(any(
                key_directions.get(k) == "left" for k in self._held_keys
            ))

            left = max(-1.0, min(1.0, forward + turn))
            right = max(-1.0, min(1.0, forward - turn))
            self._apply_drive(left, right)
        else:
            # Releasing the last key stops; old mouse input is not resumed.
            self._mouse_drive = None
            self._left = self._right = 0.0
            self._send_drive()
            self.changed.emit()

    def _apply_drive(self, left, right):
        self._left = left * self._speed
        self._right = right * self._speed
        self._send_drive()
        self.changed.emit()

    def _send_drive(self):
        if not self._online:
            return
        try:
            self.link.send(encode("drive", self._seq, left=self._left, right=self._right))
            self._seq += 1
        except OSError as exc:
            self.note("Send failed: " + str(exc), True)
            self._left = self._right = 0.0
            self._armed = False
            self.link.close()
            self._online = False

    @Slot()
    def releaseMouse(self):
        """Release mouse input without interrupting active keyboard input."""
        if self._held_keys:
            return

        self._mouse_drive = None
        self._left = self._right = 0.0
        self._send_drive()
        self.changed.emit()

    @Slot()
    def stop(self):
        self._held_keys.clear()
        self._mouse_drive = None
        self._left = self._right = 0.0
        self._send_drive()
        self.changed.emit()
    def _telemetry_status(self):
        if not self._online:
            return "disconnected"

        if not self._has_telemetry:
            return "waiting"

        age = time.monotonic() - self.telemetry.received_at
        if age * 1000 > self.config["stale_after_ms"]:
            return "stale"

        return "live"

    @Slot()
    def tick(self):
        if self._online:
            try:
                packets = self.link.receive()
            except OSError as exc:
                self.note("Receive failed: " + str(exc), True)
                self.disconnectLink()
                return
            for raw in packets:
                try:
                    packet = decode(raw)
                except ValueError:
                    self._invalid += 1
                    if self._invalid == 1 or self._invalid % 20 == 0:
                        self.note(f"Dropped malformed packet (total {self._invalid})", True)
                    continue
                if packet["type"] == "telemetry":
                    first = self.telemetry.received_at is None
                    self.telemetry.update(packet)
                    self._has_telemetry = True
                    if first:
                        self.note("First rover telemetry received")
            if self._armed:
                self._send_drive()
        self.changed.emit()

    @Slot()
    def clearEvents(self):
        self._events = []
        self.eventsChanged.emit()

    @Slot()
    def shutdown(self):
        self._timer.stop()
        self.disconnectLink()

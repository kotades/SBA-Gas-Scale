# Technical Design Specification: SBA Gas Detector Flutter Mobile App & BLE Engine

* **Date:** 2026-09-15
* **Author:** Antigravity Engineering
* **Status:** Approved by User / Ready for Implementation Planning
* **Target Stack:** Flutter (Dart 3.x), Cross-Platform iOS & Android, `flutter_blue_plus`, Riverpod, Custom Canvas

---

## 1. Executive Summary

The **SBA Gas Detector** mobile application serves as the primary cross-platform (iOS and Android) telemetry dashboard and hardware configuration tool for an ESP32-C3 powered Liquefied Petroleum Gas (LPG) safety appliance.

This document formalizes the complete architecture, physical elements, interactive screens, background Bluetooth Low Energy (BLE) engine, JSON serialization protocol, and verification standards required for development.

---

## 2. Architecture & File Directory Structure

The application adopts a feature-first architecture that strictly separates UI widgets, state providers, and the invisible BLE communication layer.

```
lib/
├── core/
│   ├── ble/
│   │   ├── ble_constants.dart             # Service UUIDs, Characteristic UUIDs, MTU target
│   │   ├── ble_service.dart               # BLE connection, scanning, GATT notifications, MTU negotiator
│   │   └── ble_command_serializer.dart    # Translates button commands and rosters into JSON
│   ├── models/
│   │   ├── telemetry_data.dart            # Gas percentage, net weight, alarm state, connection state
│   │   └── escalation_roster.dart         # SMS and Voice recipient lists
│   ├── theme/
│   │   ├── app_colors.dart                # Dark industrial palette, status colors (Safe, Warn, Alarm)
│   │   └── app_typography.dart            # Clean typography & monospace readouts
│   └── utils/
│       └── phone_validator.dart           # E.164 international dialing code regex (+234...)
├── features/
│   ├── dashboard/
│   │   ├── presentation/
│   │   │   ├── dashboard_screen.dart
│   │   │   └── widgets/
│   │   │       ├── volumetric_cylinder_painter.dart # Custom 2D animated fluid container
│   │   │       ├── gas_saturation_gauge.dart        # 240° sweeping radial dial
│   │   │       ├── emergency_alarm_banner.dart      # 4Hz flashing leak warning strobe
│   │   │       ├── manual_siren_toggle.dart         # Master hardware alarm toggle
│   │   │       └── ble_connection_badge.dart        # Persistent BLE connection indicator
│   │   └── providers/
│   │       └── dashboard_provider.dart
│   ├── contacts/
│   │   ├── presentation/
│   │   │   ├── emergency_contacts_screen.dart
│   │   │   └── widgets/
│   │   │       ├── contact_list_builder.dart        # Reusable card list with edit/delete
│   │   │       └── contact_input_modal.dart         # Input dialog with real-time validation
│   │   └── providers/
│   │       └── contacts_provider.dart
│   └── hardware/
│       ├── presentation/
│       │   ├── hardware_config_screen.dart
│       │   └── widgets/
│       │       ├── cylinder_size_dropdown.dart      # 3kg, 6kg, 12.5kg, 25kg, 50kg selector
│       │       └── tare_confirmation_modal.dart     # Safety confirmation dialog for scale zeroing
│       └── providers/
│           └── hardware_provider.dart
└── main.dart                                        # Root widget, dark theme setup, Scaffold navigation
```

---

## 3. Detailed Screen Breakdown

### 3.1 Screen 1: The Main Dashboard Screen (Telemetry Hub)

The default launch screen providing instantaneous visual assessment of gas safety and cylinder status.

1. **BLE Connection Status Icon**:
   * **Location**: Top app bar / header card.
   * **Behavior**: Displays persistent status indicator with pulse animation.
     * Connected: Emerald Green dot (`#10B981`) with `"Linked: SBA GAS DETECTOR"`.
     * Disconnected: Slate Gray dot (`#6B7280`) with an inline `"Scan / Connect"` trigger button.
2. **Volumetric Gas Cylinder Graphic (2D Fluid Wave Simulation)**:
   * **Location**: Central dominant visual element.
   * **Visual Representation**: Custom-painted metallic LPG cylinder silhouette with protective top shroud collar, brass valve stem, cylindrical body with specular highlight, and recessed foot ring.
   * **Fluid Dynamics**:
     * Sinusoidal wave equations computed in `CustomPainter`:
       $$y(x, t) = \text{levelY} + A_1 \sin(k_1 x + \omega_1 t) + A_2 \cos(k_2 x - \omega_2 t)$$
     * Continuous 60fps wave motion driven by an infinite `AnimationController`.
     * Liquid fill height smoothly interpolates to target percentage:
       $$\text{Fuel \%} = \text{clamp}\left(\frac{\text{NetWeight}}{\text{SelectedMaxKg}} \times 100, 0, 100\right)$$
     * Semi-translucent cyan gradient (`#00F2FE` to `#4FACFE`) with liquid foam highlights and glass surface reflection.
3. **Gas Saturation Gauge (Sweeping Radial Dial)**:
   * **Location**: Secondary telemetry section beneath or adjacent to the cylinder.
   * **Layout**: 240° sweeping radial arc calibrated from **0% to 100%**.
   * **Safety Zones**:
     * `0% - 20%`: Safe Zone (Emerald Green `#10B981`)
     * `21% - 59%`: Warning Zone (Amber Yellow `#F59E0B`)
     * `60% - 100%`: Danger Zone (Crimson Red `#EF4444`)
   * **Indicator**: Animated sweeping needle/arc indicator with monospace digital readout.
4. **Color-Coded Status Overlays**:
   * Background tint and card outline borders dynamically respond to system state:
     * **Safe State** (`gas <= 20%` & `netWeight >= 1.0 kg`): Dark slate navy (`#090D16`), emerald accents.
     * **Low Fuel State** (`netWeight < 1.0 kg`): Amber glowing borders (`#F59E0B`) with `"LOW FUEL (< 1.0 kg)"` banner.
     * **Leak Alarm State** (`gas > 60%` or `alarmState == 2`): Red pulsing borders.
5. **Flashing Emergency Banner**:
   * **Visibility**: Hidden by default. Triggers when `alarmState == 2` or `gasPercentage > 60%`.
   * **Animation**: Aggressive 4Hz alternating color strobe between solid `#EF4444` and `#7F1D1D`.
   * **Copy**: `🚨 CRITICAL GAS LEAK DETECTED — GSM ESCALATION ACTIVE`.
   * **Tactile**: Triggers continuous haptic feedback pulses on mobile device.
6. **Manual Siren Toggle**:
   * **Location**: Prominent interactive card on the dashboard.
   * **Function**: Master software switch to remotely engage or mute the ESP32 hardware buzzer/alarm over BLE.
   * **Payload**: Dispatches `{"cmd": "SIREN", "state": true/false}`.

---

### 3.2 Screen 2: The Emergency Contacts Screen (Escalation Roster)

Dedicated roster management screen for configuring who receives GSM alerts during a gas leak.

1. **SMS Recipient List Builder**:
   * Interface to display, add, edit, and delete phone numbers destined for automated text notifications.
   * Card list showing phone number, country code badge, and delete icon.
   * Add button triggers the validated input modal.
2. **Voice Call List Builder**:
   * Separate interface for numbers designated for sequential automated voice calls.
   * Numbered sequence badges (1. Primary, 2. Secondary, 3. Backup) to indicate call escalation order.
   * Add, edit, and delete operations.
3. **Input Validation Engine**:
   * Enforces international E.164 telephone format: `^\+[1-9]\d{7,14}$`.
   * Specifically validates presence of leading `+` and country dialing code (e.g., `+234...`).
   * Prevents submission if the format is invalid, displaying an inline error: *"Number must include international country code starting with '+' (e.g. +234...)"*.
   * Prevents duplicate phone entries in the same list.
4. **Roster Sync Action**:
   * Prominent `"Sync Roster to Device"` button serializing the updated contacts into JSON and transmitting over BLE.

---

### 3.3 Screen 3: The Hardware Configuration Screen

Appliance calibration and scale zeroing interface.

1. **Cylinder Size Selector**:
   * Dropdown selection menu supporting:
     * `3.0 kg`
     * `6.0 kg`
     * `12.5 kg`
     * `25.0 kg`
     * `50.0 kg`
   * Selection immediately updates:
     * Local storage (`SharedPreferences`) for dashboard percentage calculations.
     * Transmits `{"cmd": "SET_MAX", "max_kg": 12.5}` to the ESP32.
2. **Tare / Zero Scale Button**:
   * High-visibility action button styled with warning border.
   * Clear advisory: *"Place an empty cylinder on the scale before calibrating."*
3. **Safety Confirmation Modal**:
   * Two-step pop-up triggered by the Tare button to avoid accidental calibration erasure:
     * Title: `⚠️ Confirm Scale Zero Calibration`
     * Message: *"Ensure ONLY a completely EMPTY cylinder is placed on the scale plate. Performing this with gas in the cylinder will invalidate subsequent safety thresholds."*
     * Actions: `"Cancel"` (dismiss) and `"Confirm & Zero Scale"` (executes `{"cmd": "TARE"}`).

---

## 4. The Background BLE Engine (Invisible Logic)

### 4.1 Bluetooth Connection & MTU Size Negotiator
* **GATT Parameters**:
  * Service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
  * Characteristic UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
  * Properties: `READ`, `WRITE`, `NOTIFY`.
* **MTU Size Negotiator**:
  * Upon device connection, the engine invokes `await device.requestMtu(512);`.
  * Verifies negotiated MTU is $\ge 256$ bytes to accommodate full multi-contact JSON rosters without truncation.
  * Implements fallback packetization if an MTU $< 256$ is returned.

### 4.2 JSON Serialization Module
All app-to-hardware transmissions are formatted as standardized JSON strings:

1. **Immediate Hardware Commands**:
   * Tare Scale: `{"cmd": "TARE"}`
   * Siren Control: `{"cmd": "SIREN", "state": true}` or `{"cmd": "SIREN", "state": false}`
   * Cylinder Capacity: `{"cmd": "SET_MAX", "max_kg": 12.5}`
2. **Escalation Roster Sync**:
   * Contacts Payload:
     ```json
     {
       "cmd": "SYNC_ROSTER",
       "sms": ["+2348012345678", "+2348098765432"],
       "voice": ["+2348011112222"]
     }
     ```
3. **Full State Sync**:
   * Initial handshake configuration:
     ```json
     {
       "cmd": "SYNC_ALL",
       "max_kg": 12.5,
       "siren": false,
       "sms": ["+2348012345678"],
       "voice": ["+2348011112222"]
     }
     ```

### 4.3 Telemetry Stream Parser
The engine subscribes to Characteristic Notifications and parses incoming streams:
* Supports both legacy format: `DATA:<GasPercentage>,<NetWeight>,<AlarmState>` (e.g. `DATA:14.5,4.25,0`)
* And incoming JSON telemetry packets: `{"gas": 14.5, "weight": 4.25, "alarm": 0}`.
* Emits clean, immutable `TelemetryData` objects into the reactive provider stream.

---

## 5. Verification & Testing Strategy

1. **Unit Tests**:
   * `phone_validator_test.dart`: Test international dialing codes (+234, +1, +44), reject local numbers without `+`, reject invalid characters.
   * `ble_command_serializer_test.dart`: Verify JSON strings match the exact hardware contract.
   * `telemetry_data_test.dart`: Verify percentage calculation across all cylinder sizes (3kg, 6kg, 12.5kg, 25kg, 50kg).
2. **Widget Tests**:
   * `volumetric_cylinder_test.dart`: Verify wave painter renders without overflowing bounds.
   * `gas_saturation_gauge_test.dart`: Verify color shifting at 20% and 60% thresholds.
   * `tare_modal_test.dart`: Verify confirmation dialog triggers callback only on explicit confirmation.
3. **Integration / Manual Testing**:
   * BLE connection lifecycle, MTU negotiation logs, simulated stream notifications.

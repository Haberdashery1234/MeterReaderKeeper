# MeterReaderKeeper

A UIKit iOS app for tracking utility meter readings across multiple
buildings and floors. Built for the practical, unglamorous work of
walking a property, scanning a meter's QR code, and logging its current
reading — with a full history kept per meter and an easy way to export or
email that history afterward.

## What it does

- **Manage buildings, floors, and meters** — set up a hierarchy of
  buildings → floors → meters to match a real property.
- **Record readings** — log a new kWh reading for a meter, either by
  hand or by scanning the meter's QR code (`QrScannerViewController`) to
  jump straight to it, even from a floor that isn't the one currently
  selected.
- **Floor map view** — a visual view of a floor's meters.
- **Previous readings** — browse a meter's full reading history.
- **Export & email** — export all readings (with meter photos) to a
  plist, or email a set of readings directly from the app.

## Data model

Core Data-backed, with a straightforward hierarchy:

```
Building → Floor → Meter → Reading (date, kWh)
```

Each `Meter` also stores a photo and a `qrString` used to match it during
a scan.

## Tech stack

- UIKit, Core Data
- AVFoundation (QR scanning)
- MessageUI (emailing readings)

## Project structure

```
Source/
  Model/            Building, Floor, Meter, Reading (Core Data)
  Screens/
    Management/       Add/edit buildings, floors, meters
    ReadingsFlow/      Building selection, QR scanning, add/edit a reading
    PreviousReadings/  Reading history
  Utility/
    MeterManager.swift  Core Data stack + in-memory building/floor/meter/reading graph
    DataSeeder.swift    Seed data for development
```

## Getting started

1. Open `MeterReaderKeeper.xcodeproj` in Xcode.
2. Build and run on the Simulator or a device (QR scanning requires a
   real device with a camera).

## Status

A working, previously-used utility app — buildings/floors/meters
management, QR-based reading capture, history, and export/email are all
implemented.

## Screenshots

_Coming soon._

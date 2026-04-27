# Climate And Dashboard Notes

First target areas:

- ecobee thermostats and related sensors.
- Flair vents, pucks, rooms, and setpoints.
- HomeKit climate and occupancy surfaces.
- LG ThinQ HVAC, fans, humidity, and appliance climate signals.

Discovery output is written to `.local/inventory/` by:

```bash
scripts/inventory_climate.sh
```

Use that inventory to design:

- A whole-home climate overview.
- Room-level temperature, humidity, occupancy, vent, and setpoint cards.
- HVAC mode and schedule status.
- Alerts for rooms drifting too far from target.
- Reloadable automations/scripts before restart-only config.

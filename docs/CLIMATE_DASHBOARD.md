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

## Garage HVAC Notes

The garage HVAC package expects Flair to be configured so Home Assistant can
drive room activity:

- Set point controller: Thermostat.
- Structure mode: Auto.
- Home/Away: Home.
- Active schedule: No Schedule.
- Enable the room activity status entities for the Office and Wood Shop rooms
  if they are disabled in the entity registry.

The dashboard-facing controller is `climate.garage_hvac`. Ecobee remains heat
only, and the office AC remains cool only. Cooling demand intentionally turns
Ecobee off while the AC is running, then restores Ecobee heat when cooling
ends and the master mode still allows heat.

# Electronic dice

A pocket-sized electronic die with a pushbutton, an ATtiny1616, and seven red LEDs. It runs on three replaceable AAA alkaline cells in series for a nominal 4.5 V. The demo checks button debounce and simulates the circuit under three display and button conditions.

## Model

The project follows [Elan8 MBSE Methodology](https://github.com/elan8/mbse-methodology). [Root.sysml](model/Root.sysml) aliases the selected product as `systemOfInterest`.

| Area | Contents |
| --- | --- |
| [Context](model/00_context/Context.sysml) and [use case](model/10_usecases/UseCases.sysml) | The player presses the button and reads the pips. |
| [Stakeholder needs](model/20_requirements/StakeholderRequirements.sysml) | One throw per deliberate press and a readable result. |
| [Electronic dice](model/60_systems/00_ElectronicDice/system.sysml) | Black-box specification, gray-box architecture and white-box selection of the controller design. |
| [Roll controller](model/60_systems/RollController/system.sysml) | Controller contract and firmware behavior allocated to the microcontroller. |
| [Verification](model/60_systems/00_ElectronicDice/Verification.sysml) | Timed raw-contact inputs and assertions on roll count and face. |
| [Circuit](hardware/README.md) | Schematic, physical net connections, pip mapping, and SysML/Modelica electrical simulation. |
| [Report](model/80_documents/Documents.sysml) | Doc42 architecture, requirement traceability and Run42 verdicts. |

## Run the demo

Use PowerShell 7, Spec42 0.60.2, the SysML v2 2026-04 standard-library sources, the Elan8 domain-library sources, a Run42 build with SysML state-machine and Modelica verification, and Doc42 0.8.1. The verified local tool and dependency details are in [project.md](project.md). Commercial builds use the applicable Elan8 credentials.

From this project directory, with the tools on PATH:

```powershell
./scripts/demo.ps1 -StdlibPath <expanded-stdlib> -DomainLibraryPath <domain-library-model>
```

Pass `-Spec42`, `-Run42` and `-Doc42` to select specific executables. Each execution stores its model snapshots and evidence in a new `generated/` subdirectory. The script checks the selected model, changes only the debounce setting in the comparison snapshot, runs both snapshots, and builds `DICE-VR-001.pdf` from the verdicts. The selected run also writes CSV trajectories and SVG plots for the physical cases to `traces/`.

| Scenario | 3 ms comparison | 10 ms selected |
| --- | --- | --- |
| One bouncing press | Fail. The count and face assertions fail. | Pass. One roll registers. |
| Release bounce and a second deliberate press | Fail. The count and face assertions fail. | Pass. Two rolls register. |

The logical controller uses raw contact edges with 6 ms transient pulses and 40 ms stable intervals. The selected design qualifies closure before accepting a roll and qualifies opening before re-arming. It advances through a deterministic 1–6 sequence for verification. Display timeout, random face selection, and a compiled firmware build are follow-on work.

The circuit cases apply independently scripted button and GPIO states. They verify blank with the button released, six pips with the button held, and the center pip with the button released. The simulation uses nominal component equivalents and a fixed battery model. It covers electrical behavior for the authored fixtures. Firmware-to-circuit co-simulation, battery life and bench validation are follow-on work.

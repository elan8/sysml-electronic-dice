within ;
package ElectronicDiceBoard "Electrical equivalents for the electronic die"
  connector Pin
    Real v(unit = "V");
    flow Real i(unit = "A");
  end Pin;

  model AlkalinePack "Three series cells represented by one Thevenin equivalent"
    parameter Real voltage(unit = "V");
    parameter Real internalResistance(unit = "Ohm");
    Pin positive;
    Pin negative;
    Real current(unit = "A") "Positive on discharge";
  equation
    current = -positive.i;
    positive.i + negative.i = 0;
    positive.v - negative.v = voltage - internalResistance * current;
  end AlkalinePack;

  model Resistor
    parameter Real resistance(unit = "Ohm");
    Pin positive;
    Pin negative;
  equation
    positive.v - negative.v = resistance * positive.i;
    positive.i + negative.i = 0;
  end Resistor;

  model DecouplingCapacitor "Series ESR separates the two capacitor states"
    parameter Real capacitance(unit = "F");
    parameter Real initialVoltage(unit = "V");
    Pin positive;
    Pin negative;
    Real storedVoltage(unit = "V", start = initialVoltage, fixed = true);
  equation
    positive.i = capacitance * der(storedVoltage);
    positive.v - negative.v = storedVoltage + 0.1 * positive.i;
    positive.i + negative.i = 0;
  end DecouplingCapacitor;

  partial model ResistiveContact
    Pin positive;
    Pin negative;
    Boolean closed;
  equation
    positive.i = (positive.v - negative.v) / (if closed then 1 else 1e9);
    positive.i + negative.i = 0;
  end ResistiveContact;

  model PushButtonContact "The physical test presses at 2 ms and releases at 8 ms"
    extends ResistiveContact;
  equation
    closed = time >= 0.002 and time < 0.008;
  end PushButtonContact;

  model BouncingButtonContact "Six presses 100 ms apart, each with a 6 ms bounce"
    extends ResistiveContact;
    Real playPhase(unit = "s");
  equation
    playPhase = time - (if time < 0.1 then 0 else if time < 0.2 then 0.1
      else if time < 0.3 then 0.2 else if time < 0.4 then 0.3
      else if time < 0.5 then 0.4 else 0.5);
    closed = (playPhase >= 0.0055 and playPhase < 0.0115)
      or (playPhase >= 0.0175 and playPhase < 0.0575);
  end BouncingButtonContact;

  model LedBranch "Piecewise-linear LED with an explicit series resistor"
    parameter Real resistance(unit = "Ohm");
    parameter Real forwardVoltage(unit = "V");
    Pin positive;
    Pin negative;
    Real current(unit = "A");
  equation
    current = max(0, (positive.v - negative.v - forwardVoltage) / (resistance + 20));
    positive.i = current;
    negative.i = -current;
  end LedBranch;

  model GpioDriver "One 50 ohm push-pull output; whichever rail drives the pin carries its current"
    Pin pin;
    input Real highVoltage(unit = "V");
    input Real lowVoltage(unit = "V");
    input Boolean high;
    Real supplyCurrent(unit = "A");
    Real returnCurrent(unit = "A");
  equation
    pin.i = (pin.v - (if high then highVoltage else lowVoltage)) / 50;
    supplyCurrent = if high then -pin.i else 0;
    returnCurrent = if high then 0 else -pin.i;
  end GpioDriver;

  partial model GpioOutputs "Supply, active-low input, and seven GPIO output equivalents"
    Pin vdd;
    Pin gnd;
    Pin button;
    Pin topLeft;
    Pin topRight;
    Pin middleLeft;
    Pin center;
    Pin middleRight;
    Pin bottomLeft;
    Pin bottomRight;
    Real railVoltage(unit = "V");
    Real buttonVoltage(unit = "V");
    Boolean topLeftHigh;
    Boolean topRightHigh;
    Boolean middleLeftHigh;
    Boolean centerHigh;
    Boolean middleRightHigh;
    Boolean bottomLeftHigh;
    Boolean bottomRightHigh;
    GpioDriver topLeftDriver;
    GpioDriver topRightDriver;
    GpioDriver middleLeftDriver;
    GpioDriver centerDriver;
    GpioDriver middleRightDriver;
    GpioDriver bottomLeftDriver;
    GpioDriver bottomRightDriver;
  equation
    railVoltage = vdd.v - gnd.v;
    buttonVoltage = button.v - gnd.v;
    button.i = 0;
    topLeftDriver.high = topLeftHigh;
    connect(topLeft, topLeftDriver.pin);
    topRightDriver.high = topRightHigh;
    connect(topRight, topRightDriver.pin);
    middleLeftDriver.high = middleLeftHigh;
    connect(middleLeft, middleLeftDriver.pin);
    centerDriver.high = centerHigh;
    connect(center, centerDriver.pin);
    middleRightDriver.high = middleRightHigh;
    connect(middleRight, middleRightDriver.pin);
    bottomLeftDriver.high = bottomLeftHigh;
    connect(bottomLeft, bottomLeftDriver.pin);
    bottomRightDriver.high = bottomRightHigh;
    connect(bottomRight, bottomRightDriver.pin);
    // Connector flows of the internal drivers are included in the supply load.
    vdd.i = 0.002 + topLeftDriver.supplyCurrent + topRightDriver.supplyCurrent + middleLeftDriver.supplyCurrent + centerDriver.supplyCurrent + middleRightDriver.supplyCurrent + bottomLeftDriver.supplyCurrent + bottomRightDriver.supplyCurrent;
    gnd.i = -0.002 + topLeftDriver.returnCurrent + topRightDriver.returnCurrent + middleLeftDriver.returnCurrent + centerDriver.returnCurrent + middleRightDriver.returnCurrent + bottomLeftDriver.returnCurrent + bottomRightDriver.returnCurrent;
    topLeftDriver.highVoltage = vdd.v;
    topLeftDriver.lowVoltage = gnd.v;
    topRightDriver.highVoltage = vdd.v;
    topRightDriver.lowVoltage = gnd.v;
    middleLeftDriver.highVoltage = vdd.v;
    middleLeftDriver.lowVoltage = gnd.v;
    centerDriver.highVoltage = vdd.v;
    centerDriver.lowVoltage = gnd.v;
    middleRightDriver.highVoltage = vdd.v;
    middleRightDriver.lowVoltage = gnd.v;
    bottomLeftDriver.highVoltage = vdd.v;
    bottomLeftDriver.lowVoltage = gnd.v;
    bottomRightDriver.highVoltage = vdd.v;
    bottomRightDriver.lowVoltage = gnd.v;
  end GpioOutputs;

  partial model AtTiny1616Outputs
    extends GpioOutputs;
    Real activeFace "0 blanks the display";
  equation
    topLeftHigh = activeFace >= 1.5;
    topRightHigh = activeFace >= 3.5;
    middleLeftHigh = activeFace >= 5.5;
    centerHigh = (activeFace >= 0.5 and activeFace < 1.5)
      or (activeFace >= 2.5 and activeFace < 3.5)
      or (activeFace >= 4.5 and activeFace < 5.5);
    middleRightHigh = activeFace >= 5.5;
    bottomLeftHigh = activeFace >= 3.5;
    bottomRightHigh = activeFace >= 1.5;
  end AtTiny1616Outputs;

  model Stm32GpioIo "Seven GPIO levels from an emulated STM32F407"
    extends GpioOutputs;
    input Real pd0;
    input Real pd1;
    input Real pd2;
    input Real pd3;
    input Real pd4;
    input Real pd5;
    input Real pd6;
  equation
    topLeftHigh = pd0 >= 0.5;
    topRightHigh = pd1 >= 0.5;
    middleLeftHigh = pd2 >= 0.5;
    centerHigh = pd3 >= 0.5;
    middleRightHigh = pd4 >= 0.5;
    bottomLeftHigh = pd5 >= 0.5;
    bottomRightHigh = pd6 >= 0.5;
  end Stm32GpioIo;

  model AtTiny1616Io "Independent component verification fixture"
    extends AtTiny1616Outputs;
  equation
    activeFace = if time < 0.001 then 0 else if time < 0.006 then 6 else 1;
  end AtTiny1616Io;

  model DrivenAtTiny1616Io "Face command held between controller samples"
    extends AtTiny1616Outputs;
    input Real faceCommand;
  equation
    activeFace = faceCommand;
  end DrivenAtTiny1616Io;

  model Ground
    Pin pin;
  equation
    pin.v = 0;
  end Ground;
end ElectronicDiceBoard;

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

  model PushButtonContact "The physical test presses at 2 ms and releases at 8 ms"
    Pin positive;
    Pin negative;
  equation
    positive.i = (positive.v - negative.v) / (if time >= 0.002 and time < 0.008 then 1 else 1e9);
    positive.i + negative.i = 0;
  end PushButtonContact;

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

  model AtTiny1616Io "GPIO and load equivalent; the test drives pip commands independently of the button"
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
    Boolean showSix;
    Boolean showOne;
    GpioDriver topLeftDriver;
    GpioDriver topRightDriver;
    GpioDriver middleLeftDriver;
    GpioDriver centerDriver;
    GpioDriver middleRightDriver;
    GpioDriver bottomLeftDriver;
    GpioDriver bottomRightDriver;
  equation
    showSix = time >= 0.001 and time < 0.006;
    showOne = time >= 0.006;
    railVoltage = vdd.v - gnd.v;
    buttonVoltage = button.v - gnd.v;
    button.i = 0;
    topLeftDriver.high = showSix;
    connect(topLeft, topLeftDriver.pin);
    topRightDriver.high = showSix;
    connect(topRight, topRightDriver.pin);
    middleLeftDriver.high = showSix;
    connect(middleLeft, middleLeftDriver.pin);
    centerDriver.high = showOne;
    connect(center, centerDriver.pin);
    middleRightDriver.high = showSix;
    connect(middleRight, middleRightDriver.pin);
    bottomLeftDriver.high = showSix;
    connect(bottomLeft, bottomLeftDriver.pin);
    bottomRightDriver.high = showSix;
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
  end AtTiny1616Io;

  model Ground
    Pin pin;
  equation
    pin.v = 0;
  end Ground;
end ElectronicDiceBoard;

# MutatingQRTest
An experiment with constantly mutating QR codes

## Premise
This is an experiment for the ExiSST attendance taking system, which uses constantly changing QR codes
as an anti-spoofing measure. ExiSST, as of the time of writing, changes QR codes once every 3 seconds.

The key priority of this experiment is to
- Increase the "refresh rate" of the QR code without causing a strobing effect
- Prevent capturing QR codes as images
- Maintain reasonable performance

## About the Experiment

This is an experiment where the QR code changes *every second*, with a fancy animation to animate between
states.

### Animation
The QR code is split up into multiple "zones", usually of height and width 3.

To animate the state, each black pixel is given a unique identifier. This identifier has two parts:
- The zone it belongs to
- The number of black pixels before this black pixel, in left-right top-down order

There are two different renderers that implement this animation method:
- `QROffsetRenderer`: It renders every single possible black pixel in the top right corner of a ZStack.
They are offset according to their position, and the offset is the one that is animated.
- `QRPositionRenderer`: It renders each pixel, then uses a matched geometry effect on the black pixels.

`QROffsetRenderer` is generally less performant due to rendering more pixels, however the animation is cleaner with
no pixels that fade in and out of existence. 

`QRPositionRenderer` is generally more performant due to rendering less pixels, however the animation contains pixels
that fade in and out.

## Results

This experiment has partially achieved the objective of preventing capturing QR codes as images, and fully achieved
the objective of increasing the refresh rate.

The QR code is invalid about 1/3 of the time, meaning a picture would only have a roughly 67% chance of being valid.
Phone cameras are, of course, able to capture the QR code just fine.

With this arrangement, the QR code can refresh at about 5Hz until the iOS camera is unable to recognise the QR code.
In practical terms, this means that the refresh rate should be about 1Hz to account for distance, sensor noise, and
android devices.

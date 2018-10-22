# elm-webvr-test

Trying to get a simple WebVR project working on iOS/Safari with the webvr [polyfill](https://github.com/immersive-web/webvr-polyfill)

## Running

        yarn
        yarn start

## Current issues

* With the polyfill enabled the canvas on iOS is black, disabling the polyfill gives expected result
* Have not looked at the matrix conversion in the port in detail. It could be that the column/row order is wrong

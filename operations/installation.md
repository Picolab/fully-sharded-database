# Installation

## pico-engine

See instructions in https://github.com/Picolab/pico-engine/tree/master/packages/pico-engine#readme

## rulesets

- create a pico to represent the entire database
- install in it the rulesets `html`, `byu.hr.oit`, `byu.hr.login`, and `byu.hr.import`
- use the `byu.hr.import` ruleset to create the picos for each person

## assets

Find the `public` folder of the installed pico-engine, likely something like
```
/usr/local/lib/node_modules/pico-engine/public
```
and make a directory `images` inside it.
Copy the files from this repo into that folder.

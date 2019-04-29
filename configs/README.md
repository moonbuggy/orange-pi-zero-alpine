# Configs
 - `default`	Default build with xradio as a module.
 - `debug`	Default build with unit testing and pinctrl debug during boot.

## Notes
The `patch.*` files can be applied to the matching `*.default.config` to generate custom config files. This should make it easier to propagate universal changes to the default into the variants.

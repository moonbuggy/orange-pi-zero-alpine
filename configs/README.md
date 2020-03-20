# Configs
 - `default`	Default build with xradio as a module.
 - `regdb`	Default build with xradio as a module and wireless regdb keys built into kernel. (work in progress, possibly easier not to bother doing it this way)
 - `xradio`	Default build with xradio patched and regdb keys built into the kernel. Source must be patched to use this config, see `make linux-patch`. (work in progress, still using xradio module even if patched)
 - `debug`	Default build with unit testing and pinctrl debug during boot.

## Notes
The `patch.*` files can be applied to the matching `*.default.config` to generate custom config files. This should make it easier to propagate universal changes to the default into the variants.

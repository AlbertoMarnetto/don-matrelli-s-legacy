# Don Matrelli’s Legacy

This is the public repo for my mod of Grand Prix Circuit.

Refer to the manual (Manual.odt) for the mod description and licenses, to [my
blog](https://marnetto.net/projects/grand-prix-circuit) for details.

* `mod/` : the game mod proper.
* `src/` : source code in FASM format
* `gpc-vehicle-edit/` : a program to create/edit custom cars, derived from [cyclesmod](https://github.com/albertus82/cyclesmod)
* `utils/` : Python scripts used to develop the mod. Probably useless in a void, but who knows.

Not included: [stressed](https://github.com/dstien/stressed), the program used to edit the `.ESH` files. Get it to be able to export or change the game sprites.

## License

The files under `mod` and `utils` are licensed under the MIT license. The tool `gpc-vehicle-edit/` is licensed under the [GPL-3.0](https://github.com/albertus82/cyclesmod?tab=GPL-3.0-1-ov-file) license, since it's a derivative work of `cyclesmod`.
